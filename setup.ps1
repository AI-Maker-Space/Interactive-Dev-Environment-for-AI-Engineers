<#
=============================================================================
 AI Engineer setup: Windows                  (macOS/Linux/WSL2: setup.sh)

 Checks every tool the course needs and installs or fixes only what's
 missing. Anything it installs goes into $HOME\ai-eng, except Git (Windows
 installer) and Claude Code (its installer always uses ~\.local\bin).
 Safe to run again at any time. No administrator rights needed, except for
 installing Git (Windows asks for permission once). It also lets PowerShell
 run local scripts for your user (RemoteSigned), which npm, env.ps1 and a
 project's .venv activation need.

 Nothing is added to your permanent PATH, so the tools are only there when
 you ask for them: load them into a terminal with
   . $HOME\ai-eng\env.ps1
 and closing that terminal unloads them. The one exception is VS Code's
 'code' command, which stays on your PATH so every terminal has it.

 Run with:
   powershell -ExecutionPolicy Bypass -File $HOME\ai-eng\setup.ps1          check, and fix what's missing
   powershell -ExecutionPolicy Bypass -File $HOME\ai-eng\setup.ps1 -Check   check only: change nothing

 Options:
   -Check          Report only; change nothing
   -ToolsOnly      Skip the Git name/email and GitHub SSH steps
   -Yes            Ask no questions; take the defaults (CI=true does the same)
   -NoCopy         Don't copy the report to the clipboard
   -PythonVersion  Installed when there's no Python 3.12-3.14 already (default 3.13)
   -NodeVersion    Default 24

 Settings (environment variables, same names as setup.sh):
   PYTHON_VERSION, NODE_VERSION  used when the matching option isn't given

 Exit code: 0 when nothing failed (warnings are fine), 1 otherwise.
 Works in Windows PowerShell 5.1 and PowerShell 7. Keep this file ASCII-only:
 PowerShell 5.1 misreads other characters in files without a BOM.
=============================================================================
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$ToolsOnly,
    [switch]$Yes,
    [switch]$NoCopy,
    [string]$PythonVersion = $(if ($env:PYTHON_VERSION) { $env:PYTHON_VERSION } else { '3.13' }),
    [int]$NodeVersion = $(if ($env:NODE_VERSION) { [int]$env:NODE_VERSION } else { 24 })
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow in 5.1 with a progress bar
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { Write-Verbose 'TLS setting unavailable' }

$AiEng      = Join-Path $HOME 'ai-eng'
$LogFile    = Join-Path $AiEng 'setup.log'
$ReportFile = Join-Path $AiEng 'setup-report.txt'
$LocalBin   = Join-Path $HOME '.local\bin'

# What the student's own terminal had before this script changes anything.
$active = [bool]$env:AI_ENG_HOME
$codeInTerminal = [bool](Get-Command 'code' -ErrorAction SilentlyContinue)
$EnvFile = Join-Path $AiEng 'env.ps1'
$PyRange = '>=3.12,<3.15'; $PyRangeText = '3.12-3.14'

$checkOnly   = $Check.IsPresent
$interactive = -not ($Yes.IsPresent -or $env:CI -eq 'true')
try { if ([Console]::IsInputRedirected) { $interactive = $false } } catch { $interactive = $false }
$doCopy = -not ($NoCopy.IsPresent -or $env:CI -eq 'true')

# ============================================================================ output
$script:Report = New-Object System.Collections.Generic.List[string]
$script:NFail = 0; $script:NWarn = 0; $script:NDone = 0

function Add-Line([string]$Text) { $script:Report.Add($Text) }
function Write-Row([string]$Color, [string]$Tag, [string]$Label, [string]$Message) {
    Write-Host '  ' -NoNewline
    Write-Host ('{0,-6}' -f $Tag) -ForegroundColor $Color -NoNewline
    Write-Host (' {0,-16} {1}' -f $Label, $Message)
    Add-Line ('{0,-6} {1,-16} {2}' -f $Tag, $Label, $Message)
}
function Write-Ok([string]$L, [string]$M)   { Write-Row 'Green'    '[ OK ]' $L $M }
function Write-Done([string]$L, [string]$M) { Write-Row 'Cyan'     '[DONE]' $L $M; $script:NDone++ }
function Write-Info([string]$L, [string]$M) { Write-Row 'DarkGray' '[ -- ]' $L $M }
function Write-Warn([string]$L, [string]$M) { Write-Row 'Yellow'   '[WARN]' $L $M; $script:NWarn++ }
function Write-Fail([string]$L, [string]$M) { Write-Row 'Red'      '[FAIL]' $L $M; $script:NFail++ }
function Write-Hint([string]$Text) {
    Write-Host ('         -> ' + $Text) -ForegroundColor DarkGray
    Add-Line ('         -> ' + $Text)
}
function Write-Say([string]$Text) { Write-Host ('         ' + $Text + '...') -ForegroundColor DarkGray }
function Write-Section([string]$Title) {
    Write-Host ''; Write-Host $Title -ForegroundColor White
    Add-Line ''; Add-Line ('## ' + $Title)
}

function Test-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Get-FirstLine([string]$Exe, [string[]]$Arguments) {
    try {
        $out = & $Exe @Arguments 2>$null | Select-Object -First 1
        if ($null -eq $out) { return '' }
        return ([string]$out).Trim()
    } catch { return '' }
}

function Add-LogLine([string]$Text) {
    if (Test-Path -LiteralPath $AiEng) { Add-Content -LiteralPath $LogFile -Value $Text -Encoding UTF8 }
}

# Runs a block with its output going to the log. On failure, shows the end of it.
function Invoke-Logged([string]$What, [scriptblock]$Block) {
    Add-LogLine ('')
    Add-LogLine ('=== {0}  {1}' -f (Get-Date -Format 'HH:mm:ss'), $What)
    $global:LASTEXITCODE = 0
    $ok = $true
    try {
        $out = @(& $Block 2>&1 | ForEach-Object { [string]$_ })
        if ($LASTEXITCODE -ne 0) { $ok = $false }
    } catch {
        $out = @([string]$_)
        $ok = $false
    }
    if ($out.Count -gt 0) { Add-Content -LiteralPath $LogFile -Value $out -Encoding UTF8 }
    if (-not $ok) {
        $out | Select-Object -Last 8 | ForEach-Object { Write-Host ('         | ' + $_) -ForegroundColor DarkGray }
    }
    return $ok
}

function Read-YesNo([string]$Question, [bool]$Default) {
    if (-not $interactive) { return $Default }
    Write-Host ''
    $answer = Read-Host ('  ' + $Question)
    if (-not $answer) { return $Default }
    return ($answer -match '^[Yy]')
}

# ============================================================================ where are we?
$osName = 'Windows'
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $osName = '{0} (build {1})' -f $os.Caption, $os.BuildNumber
} catch { Write-Verbose 'Could not read OS details' }
$arch = $env:PROCESSOR_ARCHITECTURE

if ($env:TERM_PROGRAM -eq 'vscode') {
    $terminal = 'VS Code'
    $restartHint = 'Close every VS Code window and open VS Code again'
} elseif ($env:TERMINAL_EMULATOR -eq 'JetBrains-JediTerm') {
    $terminal = 'JetBrains IDE'
    $restartHint = 'Quit the IDE completely (File > Exit) and open it again'
} else {
    $terminal = 'unknown'
    $restartHint = 'Close this terminal window and open a new one'
}
$psDesc = 'PowerShell {0}' -f $PSVersionTable.PSVersion.ToString()
$rerun = 'Run the setup again (without -Check): it fixes what is missing'
$logHint = "Details are in $LogFile. Run the setup again; if it fails the same way, share that file"

# ============================================================================ PATH helpers
# Windows keeps PATH in the registry. A terminal only reads it when the app that
# started it (VS Code, a JetBrains IDE) started.
function Get-SavedPathDir {
    $dirs = @()
    foreach ($scope in 'Machine', 'User') {
        $value = [Environment]::GetEnvironmentVariable('Path', $scope)
        if ($value) {
            foreach ($d in $value.Split(';')) { if ($d) { $dirs += [Environment]::ExpandEnvironmentVariables($d).TrimEnd('\') } }
        }
    }
    return $dirs
}

# Makes this run see what a new terminal would see.
function Update-SessionPath {
    $env:Path = ((Get-SavedPathDir) + ($env:Path -split ';') | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Test-UserPathHas([string]$Dir) {
    $value = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $value) { return $false }
    foreach ($d in $value.Split(';')) {
        if ([Environment]::ExpandEnvironmentVariables($d).TrimEnd('\') -ieq $Dir.TrimEnd('\')) { return $true }
    }
    return $false
}

# Adds a folder to the user PATH, keeping %VARIABLE% entries intact, and backs
# the old value up first.
function Add-UserPath([string]$Dir) {
    if (Test-UserPathHas $Dir) { return $false }
    $key = Get-Item -LiteralPath 'HKCU:\Environment'
    $raw = [string]$key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $backup = Join-Path $AiEng 'path-backup.txt'
    Add-Content -LiteralPath $backup -Value ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $raw) -Encoding UTF8
    if ($raw) { $new = $Dir + ';' + $raw } else { $new = $Dir }
    Set-ItemProperty -LiteralPath 'HKCU:\Environment' -Name 'Path' -Value $new -Type ExpandString
    # Setting any user variable through .NET tells Windows that the environment changed.
    [Environment]::SetEnvironmentVariable('AI_ENG_SETUP_REFRESH', '1', 'User')
    [Environment]::SetEnvironmentVariable('AI_ENG_SETUP_REFRESH', $null, 'User')
    $env:Path = $Dir + ';' + $env:Path
    return $true
}

function Find-Hidden([string]$Name) {
    $dirs = @(Get-SavedPathDir) + @((Join-Path $AiEng 'bin'), (Join-Path $AiEng 'node'), $LocalBin)
    if ($env:LOCALAPPDATA) { $dirs += Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin' }
    foreach ($dir in $dirs) {
        foreach ($ext in '.exe', '.cmd') {
            try {
                $candidate = Join-Path $dir ($Name + $ext)
                if (Test-Path -LiteralPath $candidate) { return $candidate }
            } catch { Write-Verbose "Skipping unreadable PATH entry: $dir" }
        }
    }
    return $null
}

function Write-Missing([string]$Label, [string]$Name) {
    $where = Find-Hidden $Name
    if ($where) {
        Write-Warn $Label "installed ($where), but this terminal can't see it"
        Write-Hint $restartHint
    } else {
        Write-Fail $Label 'not installed'
        Write-Hint $rerun
    }
}

function Get-Major([string]$Version) {
    $m = 0
    [void][int]::TryParse(($Version.TrimStart('v').Split('.')[0]), [ref]$m)
    return $m
}

# ============================================================================ header
if ($checkOnly) { $modeText = 'check only: nothing will be changed' } else { $modeText = "checks each item and fixes what's missing" }
Write-Host 'AI Engineer setup ' -ForegroundColor White -NoNewline
Write-Host "($modeText)" -ForegroundColor DarkGray
Write-Host ('System: {0} ({1}) | Terminal: {2}, {3}' -f $osName, $arch, $terminal, $psDesc) -ForegroundColor DarkGray
if ($checkOnly) { $flag = ' -Check' } else { $flag = '' }
Add-Line ('AI Engineer setup{0}  {1}' -f $flag, (Get-Date -Format 'yyyy-MM-dd HH:mm'))
Add-Line ('System:   {0} ({1})' -f $osName, $arch)
Add-Line ('Terminal: {0}, {1}' -f $terminal, $psDesc)

# ============================================================================ base folder
Write-Section 'Base folder (~\ai-eng)'

if ($checkOnly) {
    # Students who followed the step-by-step guide installed the tools themselves,
    # so there's no ~\ai-eng to find. That's fine: the tool checks below decide.
    if (Test-Path -LiteralPath $EnvFile) { Write-Ok 'Base folder' $AiEng }
    else { Write-Info 'Base folder' '~\ai-eng not created (fine if you installed the tools yourself)' }
} else {
    foreach ($d in 'bin', 'python') { New-Item -ItemType Directory -Force -Path (Join-Path $AiEng $d) | Out-Null }
    Add-LogLine ''
    Add-LogLine ('=== {0}  setup started: {1}, {2}, {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $osName, $terminal, $psDesc)
    $readme = @(
        'This folder holds the tools installed by the AI Engineer setup.',
        '',
        '  bin\            uv (Python package manager)',
        '  python\         Python versions installed by uv',
        '  node\           Node.js (only if you did not already have Node.js 24 or newer)',
        '  env.ps1         loads all of the above into a terminal:  . $HOME\ai-eng\env.ps1',
        '  setup.ps1       run again at any time (add -Check to only check):',
        '                  powershell -ExecutionPolicy Bypass -File $HOME\ai-eng\setup.ps1',
        '  setup.log       what the last runs did, for troubleshooting',
        '  path-backup.txt your user PATH before the setup changed it',
        '',
        'Nothing loads these tools automatically: run ". $HOME\ai-eng\env.ps1" in each',
        'terminal where you want them. Closing the terminal unloads them again.',
        '',
        'Git is installed the usual Windows way, and Claude Code always uses ~\.local\bin',
        '(env.ps1 adds that too).',
        '',
        'To remove everything: delete this folder.'
    )
    Set-Content -LiteralPath (Join-Path $AiEng 'README.txt') -Value $readme -Encoding UTF8
    Write-Ok 'Base folder' $AiEng
}

# Script policy. Ignore the Process scope: it only covers this run (started with
# -ExecutionPolicy Bypass), not the student's normal terminal, where npm.ps1 runs.
function Get-EffectivePolicy {
    foreach ($scope in 'MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine') {
        try {
            $p = [string](Get-ExecutionPolicy -Scope $scope -ErrorAction Stop)
            if ($p -ne 'Undefined') { return @($scope, $p) }
        } catch { Write-Verbose "Could not read execution policy for $scope" }
    }
    return @('Default', 'Restricted')
}
$policy = Get-EffectivePolicy
if ($policy[1] -notin @('Restricted', 'AllSigned')) {
    Write-Ok 'Script policy' $policy[1]
} elseif ($policy[0] -in @('MachinePolicy', 'UserPolicy')) {
    Write-Warn 'Script policy' "$($policy[1]), set by your organisation, so npm, env.ps1 and .venv activation won't run"
    Write-Hint 'Ask your IT team to allow RemoteSigned. Until then, use npm.cmd instead of npm'
} elseif ($checkOnly) {
    Write-Warn 'Script policy' "$($policy[1]), so npm, env.ps1 and .venv activation won't run in a normal terminal"
    Write-Hint "$rerun, or run: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
} else {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
        Write-Done 'Script policy' 'RemoteSigned, so commands like npm can run'
    } catch {
        Write-Warn 'Script policy' "couldn't be changed: $($_.Exception.Message)"
    }
}

# env.ps1 loads the tools into one terminal. Closing the terminal unloads them.
$envScript = @'
# Loads the AI Engineer tools into THIS terminal only:  . $HOME\ai-eng\env.ps1
# Closing the terminal unloads them. Written by the AI Engineer setup and
# rewritten every time it runs, so put your own settings elsewhere.
$env:AI_ENG_HOME = '__AI_ENG__'
& {
    # Also picks up anything installed since this terminal opened (e.g. Git).
    $saved = @([Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';'
    $first = @("$env:AI_ENG_HOME\bin", "$HOME\.local\bin", "$env:AI_ENG_HOME\node", "$env:APPDATA\npm")
    $all = $first + ($env:Path -split ';') + ($saved -split ';')
    $env:Path = ($all | Where-Object { $_ } | Select-Object -Unique) -join ';'
}
$env:UV_PYTHON_INSTALL_DIR = "$env:AI_ENG_HOME\python"
'@
if (-not $checkOnly) {
    # Doubling apostrophes keeps paths like C:\Users\O'Brien valid inside the single quotes.
    Set-Content -LiteralPath $EnvFile -Value ($envScript.Replace('__AI_ENG__', $AiEng.Replace("'", "''"))) -Encoding UTF8
}

# Older versions of this setup made ~\ai-eng permanent: user PATH entries and
# the UV_PYTHON_INSTALL_DIR variable. Tools now load per terminal instead.
function Get-OldPermanentEntry {
    $found = @()
    $value = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($value) {
        foreach ($d in $value.Split(';')) {
            if ($d -and [Environment]::ExpandEnvironmentVariables($d).StartsWith($AiEng, [StringComparison]::OrdinalIgnoreCase)) { $found += $d }
        }
    }
    $v = [Environment]::GetEnvironmentVariable('UV_PYTHON_INSTALL_DIR', 'User')
    if ($v -and $v.StartsWith($AiEng, [StringComparison]::OrdinalIgnoreCase)) { $found += 'UV_PYTHON_INSTALL_DIR' }
    return $found
}
$oldEntries = @(Get-OldPermanentEntry)
if ($oldEntries.Count -gt 0) {
    if ($checkOnly) {
        Write-Warn 'Environment' 'an older setup made ~\ai-eng permanent on your PATH'
        Write-Hint $rerun
    } else {
        $key = Get-Item -LiteralPath 'HKCU:\Environment'
        $raw = [string]$key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
        Add-Content -LiteralPath (Join-Path $AiEng 'path-backup.txt') -Value ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $raw) -Encoding UTF8
        $kept = @($raw.Split(';') | Where-Object { $_ -and -not [Environment]::ExpandEnvironmentVariables($_).StartsWith($AiEng, [StringComparison]::OrdinalIgnoreCase) })
        Set-ItemProperty -LiteralPath 'HKCU:\Environment' -Name 'Path' -Value ($kept -join ';') -Type ExpandString
        [Environment]::SetEnvironmentVariable('UV_PYTHON_INSTALL_DIR', $null, 'User')   # also tells Windows the environment changed
        Write-Done 'Environment' '~\ai-eng is no longer permanent on your PATH (loaded per terminal now)'
    }
}

if ($active) {
    Write-Ok 'Tools loaded' 'env.ps1 is active in this terminal'
} elseif ($checkOnly -and (Test-Path -LiteralPath $EnvFile)) {
    Write-Info 'Tools loaded' 'not in this terminal. To use them: . $HOME\ai-eng\env.ps1'
}

# From here on, the script runs with env.ps1 loaded: the same tools a student
# gets after ". $HOME\ai-eng\env.ps1". This doesn't touch their own terminal.
if (Test-Path -LiteralPath $EnvFile) { . $EnvFile }

# ============================================================================ tools
Write-Section 'Tools'

# ---- Git (also gives Claude Code its bash shell)
if (Test-Command 'git') {
    Write-Ok 'Git' ((Get-FirstLine 'git' @('--version')) -replace '^git version\s*', '')
} elseif ($checkOnly) {
    Write-Missing 'Git' 'git'
} elseif (-not (Test-Command 'winget')) {
    Write-Fail 'Git' 'not installed, and winget (needed to install it) is missing'
    Write-Hint 'Install "App Installer" from the Microsoft Store, or Git from git-scm.com, then run the setup again'
} else {
    Write-Host '         Installing Git. If Windows asks for permission, click Yes.' -ForegroundColor DarkGray
    $ok = Invoke-Logged 'winget install Git.Git' {
        winget install --exact --id Git.Git --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    Update-SessionPath
    if (Test-Command 'git') { Write-Done 'Git' (((Get-FirstLine 'git' @('--version')) -replace '^git version\s*', '') + ' installed') }
    else { Write-Fail 'Git' "couldn't be installed"; Write-Hint $logHint }
}

# ---- uv
if (Test-Command 'uv') {
    Write-Ok 'uv' ((Get-FirstLine 'uv' @('--version')) -replace '^uv\s+(\S+).*$', '$1')
} elseif ($checkOnly) {
    Write-Missing 'uv' 'uv'
} else {
    Write-Say 'installing uv into ~\ai-eng\bin'
    $env:UV_INSTALL_DIR = Join-Path $AiEng 'bin'   # these only last for this run
    $env:UV_NO_MODIFY_PATH = '1'
    $env:INSTALLER_NO_MODIFY_PATH = '1'
    $ok = Invoke-Logged 'uv installer' {
        powershell -NoProfile -ExecutionPolicy Bypass -Command 'irm https://astral.sh/uv/install.ps1 | iex'
    }
    if ($ok -and (Test-Command 'uv')) {
        Write-Done 'uv' (((Get-FirstLine 'uv' @('--version')) -replace '^uv\s+(\S+).*$', '$1') + ' installed in ~\ai-eng\bin')
    } else { Write-Fail 'uv' "couldn't be installed"; Write-Hint $logHint }
}

# ---- Python: any version from 3.12 to 3.14 is fine. If there's none,
# uv installs $PythonVersion into ~\ai-eng\python.
function Get-PythonVersionText([string]$Exe) {
    # No quotes inside: Windows PowerShell 5.1 strips double quotes from arguments
    # passed to programs, which silently broke an earlier version of this line.
    return Get-FirstLine $Exe @('-c', 'import sys; print(*sys.version_info[:3], sep=chr(46))')
}
if (-not (Test-Command 'uv')) {
    Write-Info 'Python' 'not checked (needs uv)'
} else {
    $pyInstalled = $false
    $py = Get-FirstLine 'uv' @('python', 'find', '--no-project', $PyRange)
    $pyVer = ''
    if ($py -and (Test-Path -LiteralPath $py)) { $pyVer = Get-PythonVersionText $py }
    if ($pyVer) {
        Write-Ok 'Python' $pyVer
    } elseif ($py -and (Test-Path -LiteralPath $py)) {
        Write-Warn 'Python' "found at $py, but it didn't report its version"
        Write-Hint "Try running it: & '$py' --version"
    } elseif ($checkOnly) {
        Write-Fail 'Python' "no Python $PyRangeText installed"; Write-Hint $rerun
    } else {
        Write-Say "installing Python $PythonVersion into ~\ai-eng\python"
        $ok = Invoke-Logged "uv python install $PythonVersion" { uv python install $PythonVersion }
        $py = Get-FirstLine 'uv' @('python', 'find', '--no-project', $PythonVersion)
        if ($ok -and $py) {
            Write-Done 'Python' ((Get-PythonVersionText $py) + ' installed in ~\ai-eng\python')
            $pyInstalled = $true
        } else { Write-Fail 'Python' "$PythonVersion couldn't be installed"; Write-Hint $logHint }
    }

    # A default for new projects matters only when you've chosen one, or when
    # the setup had to install Python itself (so uv picks that one).
    Push-Location -LiteralPath ([IO.Path]::GetPathRoot($HOME))   # outside any project
    $pin = Get-FirstLine 'uv' @('python', 'pin', '--global')
    Pop-Location
    if ($pin -match '^3\.1[2-4]($|\.)') {
        Write-Ok 'Default Python' $pin
    } elseif ($pin -match '^\d') {
        Write-Info 'Default Python' "$pin (your setting, kept)"
    } elseif ($pyInstalled) {
        if (Invoke-Logged "uv python pin --global $PythonVersion" { uv python pin --global $PythonVersion }) {
            Write-Done 'Default Python' "$PythonVersion for projects that don't choose their own"
        } else {
            Write-Warn 'Default Python' "couldn't be set"; Write-Hint $logHint
        }
    }
}

# ---- Node.js: kept if it's new enough, otherwise a portable copy in ~\ai-eng\node
$nodeHome = Join-Path $AiEng 'node'
function Install-PortableNode {
    $ErrorActionPreference = 'Stop'
    if ($arch -eq 'ARM64') { $plat = 'win-arm64' } else { $plat = 'win-x64' }
    $base = "https://nodejs.org/dist/latest-v$NodeVersion.x"
    $sums = [string](Invoke-WebRequest -Uri "$base/SHASUMS256.txt" -UseBasicParsing -TimeoutSec 30).Content
    $line = $sums -split "`n" | Where-Object { $_ -match "^([0-9a-f]{64})\s+(node-v[\d.]+-$plat\.zip)\s*$" } | Select-Object -First 1
    if (-not $line) { throw "No $plat download listed in $base/SHASUMS256.txt" }
    [void]($line -match "^([0-9a-f]{64})\s+(node-v[\d.]+-$plat\.zip)\s*$")
    $hash = $Matches[1]; $file = $Matches[2]
    $zip = Join-Path $env:TEMP $file
    "Downloading $base/$file"
    Invoke-WebRequest -Uri "$base/$file" -OutFile $zip -UseBasicParsing -TimeoutSec 600
    $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $hash) { Remove-Item -LiteralPath $zip -Force; throw "Checksum mismatch for $file" }
    $tmp = Join-Path $AiEng 'node-download'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    if (Test-Path -LiteralPath $nodeHome) { Remove-Item -LiteralPath $nodeHome -Recurse -Force }
    Move-Item -LiteralPath (Join-Path $tmp ($file -replace '\.zip$', '')) -Destination $nodeHome
    Remove-Item -LiteralPath $tmp -Recurse -Force
    Remove-Item -LiteralPath $zip -Force
    "Installed $file into $nodeHome"
}

$nodeCmd = Get-Command 'node' -ErrorAction SilentlyContinue
$nodeVer = ''
if ($nodeCmd) { $nodeVer = (Get-FirstLine 'node' @('--version')).TrimStart('v') }
$nodeOk = $nodeVer -and ((Get-Major $nodeVer) -ge $NodeVersion)

if ($nodeOk) {
    Write-Ok 'Node.js' $nodeVer
} elseif ($checkOnly) {
    if ($nodeVer) { Write-Warn 'Node.js' "$nodeVer is older than the course needs ($NodeVersion+)"; Write-Hint $rerun }
    else { Write-Missing 'Node.js' 'node' }
} elseif ($env:NVM_HOME) {
    Write-Warn 'Node.js' "your Node.js is managed by nvm-windows and is older than $NodeVersion"
    Write-Hint "nvm install $NodeVersion, then nvm use $NodeVersion (in a terminal opened as administrator)"
} else {
    Write-Say "installing Node.js $NodeVersion into ~\ai-eng\node"
    $ok = Invoke-Logged "portable Node.js $NodeVersion" { Install-PortableNode }
    $newNode = Join-Path $nodeHome 'node.exe'
    if ($ok -and (Test-Path -LiteralPath $newNode)) {
        . $EnvFile   # env.ps1 puts ~\ai-eng\node first, ahead of any older system-wide Node.js
        $v = (Get-FirstLine $newNode @('--version')).TrimStart('v')
        Write-Done 'Node.js' "$v installed in ~\ai-eng\node"
    } else {
        Write-Fail 'Node.js' "$NodeVersion couldn't be installed"; Write-Hint $logHint
    }
}
if (Test-Command 'node') {
    # npm.cmd, not npm: npm.ps1 depends on the script policy checked above.
    if (Test-Command 'npm.cmd') { Write-Ok 'npm' (Get-FirstLine 'npm.cmd' @('--version')) }
    else { Write-Missing 'npm' 'npm' }
}

# ---- Claude Code (its installer always uses ~\.local\bin)
if (Test-Command 'claude') {
    Write-Ok 'Claude Code' ((Get-FirstLine 'claude' @('--version')) -replace '^(\S+).*$', '$1')
} elseif ($checkOnly) {
    Write-Missing 'Claude Code' 'claude'
} else {
    Write-Say 'installing Claude Code'
    $ok = Invoke-Logged 'Claude Code installer' {
        powershell -NoProfile -ExecutionPolicy Bypass -Command 'irm https://claude.ai/install.ps1 | iex'
    }
    if ($ok -and (Test-Command 'claude')) {
        Write-Done 'Claude Code' (((Get-FirstLine 'claude' @('--version')) -replace '^(\S+).*$', '$1') + ' installed')
    } else { Write-Fail 'Claude Code' "couldn't be installed"; Write-Hint $logHint }
}

# ---- VS Code's `code` command (VS Code itself is installed by hand first)
$codeBin = $null
$codeDirs = @()
if ($env:LOCALAPPDATA) { $codeDirs += Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin' }
if ($env:ProgramFiles) { $codeDirs += Join-Path $env:ProgramFiles 'Microsoft VS Code\bin' }
foreach ($d in $codeDirs) {
    if (Test-Path -LiteralPath (Join-Path $d 'code.cmd')) { $codeBin = $d; break }
}
# This is the one thing kept on your permanent PATH, so every terminal has it.
$codeAdded = $false
if ($codeInTerminal) {
    Write-Ok 'VS Code' ((Get-FirstLine 'code.cmd' @('--version')) + " ('code' command works)")
} elseif ($codeBin) {
    if ((Get-SavedPathDir) -contains $codeBin.TrimEnd('\')) {
        if ($checkOnly) { Write-Warn 'VS Code' "'code' command is set up, but this terminal opened before that"; Write-Hint $restartHint }
        else { Write-Ok 'VS Code' "'code' command set up (new VS Code windows)" }
    } elseif ($checkOnly) {
        Write-Warn 'VS Code' "installed, but the 'code' command isn't set up"; Write-Hint $rerun
    } else {
        [void](Add-UserPath $codeBin)
        $codeAdded = $true
        Write-Done 'VS Code' "'code' command added to your PATH (after VS Code restarts)"
    }
} elseif ($terminal -eq 'JetBrains IDE') {
    Write-Info 'VS Code' "not installed (fine: you're using a JetBrains IDE)"
} elseif ($env:CI -eq 'true') {
    Write-Info 'VS Code' 'not installed (fine on a CI runner)'
} else {
    Write-Warn 'VS Code' 'not installed'
    Write-Hint 'Install it from code.visualstudio.com (step 1 of the guide), then run the setup again'
}

# ============================================================================ git and github
if (-not $ToolsOnly.IsPresent) {
    Write-Section 'Git and GitHub'

    if (-not (Test-Command 'git')) {
        Write-Info 'Git identity' 'not checked (needs Git)'
    } else {
        $name  = Get-FirstLine 'git' @('config', '--global', 'user.name')
        $email = Get-FirstLine 'git' @('config', '--global', 'user.email')
        if ($name -and $email) {
            Write-Ok 'Git identity' $name
        } elseif ($checkOnly) {
            Write-Fail 'Git identity' 'name or email not set'; Write-Hint $rerun
        } elseif (-not $interactive) {
            Write-Warn 'Git identity' 'name or email not set (needs your answer)'; Write-Hint 'Run the setup again in a terminal'
        } else {
            Write-Host ''
            Write-Host '  Git labels your work with a name and email.'
            $tries = 0
            while (-not $name -and $tries -lt 5) { $name = (Read-Host '  Your name (e.g. Ana Silva)').Trim(); $tries++ }
            Write-Host '  Tip: GitHub can give you a private email for this, so your real one stays hidden.'
            Write-Host '  Find it at github.com/settings/emails (it ends in @users.noreply.github.com).'
            $tries = 0
            while ($email -notmatch '^\S+@\S+\.\S+$' -and $tries -lt 5) { $email = (Read-Host '  Email for your work').Trim(); $tries++ }
            if ($name -and $email -match '^\S+@\S+\.\S+$') {
                & git config --global user.name $name
                & git config --global user.email $email
                Write-Done 'Git identity' "set ($name)"
            } else {
                Write-Fail 'Git identity' 'name or email not set'; Write-Hint 'Run the setup again and answer both questions'
            }
        }
        if (-not $checkOnly -and -not (Get-FirstLine 'git' @('config', '--global', 'init.defaultBranch'))) {
            & git config --global init.defaultBranch main
        }
    }

    # ---- SSH key, registered on GitHub
    $ssh = $null; $keygen = $null
    $sshCmd = Get-Command 'ssh' -ErrorAction SilentlyContinue
    if ($sshCmd) { $ssh = $sshCmd.Source; $keygen = Join-Path (Split-Path $ssh) 'ssh-keygen.exe' }
    elseif (Test-Path -LiteralPath "$env:ProgramFiles\Git\usr\bin\ssh.exe") {
        $ssh = "$env:ProgramFiles\Git\usr\bin\ssh.exe"; $keygen = "$env:ProgramFiles\Git\usr\bin\ssh-keygen.exe"
    }
    $key = Join-Path $HOME '.ssh\id_ed25519'

    function Test-GitHub {
        $opts = @('-T', '-o', 'ConnectTimeout=10')
        if ($checkOnly -or -not $interactive) { $opts += @('-o', 'BatchMode=yes') }
        if (-not $checkOnly) { $opts += @('-o', 'StrictHostKeyChecking=accept-new') }
        $out = (& $ssh @opts 'git@github.com' 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
        if ($out -match 'Hi ([^!]+)! You.ve successfully authenticated') { return @('ok', $Matches[1]) }
        if ($out -match 'Host key verification failed') { return @('hostkey', '') }
        if ($out -match 'Permission denied') { return @('denied', '') }
        if ($out -match 'timed out|refused|Could not resolve') { return @('network', '') }
        return @('other', (($out -split "`n")[0]))
    }

    $state = @('', '')
    if (-not $ssh) {
        $state = @('nossh', '')
    } else {
        # Test whatever key is already there first (e.g. an id_rsa from an earlier
        # guide), so a key that already works doesn't get a redundant new one beside it.
        if ((Test-Path -LiteralPath $key) -or (Get-ChildItem -Path (Join-Path $HOME '.ssh\id_*.pub') -ErrorAction SilentlyContinue)) { $state = Test-GitHub }
        else { $state = @('nokey', '') }
        # Make a key only when there's none, or GitHub turned the existing ones down.
        # A network problem says nothing about the keys, so it never triggers a new one.
        if (-not $checkOnly -and -not (Test-Path -LiteralPath $key) -and ($state[0] -in @('nokey', 'denied'))) {
            New-Item -ItemType Directory -Force -Path (Join-Path $HOME '.ssh') | Out-Null
            $comment = Get-FirstLine 'git' @('config', '--global', 'user.email')
            if (-not $comment) { $comment = $env:USERNAME }
            # One argument string, so the empty passphrase ("") survives in PowerShell 5.1 and 7.
            try {
                $p = Start-Process -FilePath $keygen -ArgumentList "-t ed25519 -q -N `"`" -f `"$key`" -C `"$comment`"" -Wait -NoNewWindow -PassThru -ErrorAction Stop
                $created = ($p.ExitCode -eq 0)
            } catch { $created = $false }
            if ($created) { Write-Done 'SSH key' 'created ~\.ssh\id_ed25519'; $state = Test-GitHub }
            else { Write-Fail 'SSH key' "couldn't be created" }
        }
    }

    if (-not $checkOnly -and $state[0] -eq 'denied' -and $interactive -and (Test-Path -LiteralPath "$key.pub")) {
        $pub = (Get-Content -LiteralPath "$key.pub" -Raw).Trim()
        Write-Host ''
        Write-Host '  Now let GitHub know this computer is yours:'
        try { Set-Clipboard -Value $pub -ErrorAction Stop; Write-Host "   1. Your computer's key has been copied." }
        catch { Write-Host "   1. Copy this whole line (your computer's key):"; Write-Host ''; Write-Host "      $pub"; Write-Host '' }
        Write-Host '   2. In the GitHub page that opens (sign in first if asked):'
        Write-Host "      Title: anything, e.g. 'My laptop'.  Key: paste.  Then click 'Add SSH key'."
        try { Start-Process 'https://github.com/settings/ssh/new' } catch { Write-Host '      Open https://github.com/settings/ssh/new in your browser.' }
        for ($i = 0; $i -lt 3; $i++) {
            [void](Read-Host "`n  Press Enter once you have added the key")
            $state = Test-GitHub
            if ($state[0] -ne 'denied') { break }
            Write-Host "  GitHub doesn't accept the key yet. Check it was saved, and wait a few seconds."
        }
        if ($state[0] -eq 'ok') { $script:NDone++ }
    }

    switch ($state[0]) {
        'ok'      { Write-Ok 'GitHub SSH' ('connected as ' + $state[1]) }
        'nossh'   { Write-Fail 'GitHub SSH' 'ssh not found'; Write-Hint 'Settings > System > Optional features > add "OpenSSH Client"' }
        'nokey'   { Write-Fail 'GitHub SSH' 'this computer has no SSH key yet'; Write-Hint $rerun }
        'hostkey' { Write-Fail 'GitHub SSH' "this computer hasn't connected to GitHub before"; Write-Hint $rerun }
        'denied'  { Write-Fail 'GitHub SSH' "GitHub doesn't know this computer's key yet"
                    Write-Hint 'If your key has a passphrase, test it with: ssh -T git@github.com'
                    Write-Hint "$rerun and follow the GitHub step" }
        'network' { Write-Fail 'GitHub SSH' "can't reach github.com (network or firewall)"
                    Write-Hint "Some networks block SSH. See TROUBLESHOOTING.md: 'SSH over port 443'" }
        default   { Write-Warn 'GitHub SSH' ("couldn't be tested: " + $state[1]) }
    }
}

# ============================================================================ summary
Write-Host ''
if ($script:NFail -gt 0) {
    $summary = "$($script:NFail) problem(s) to fix, $($script:NWarn) warning(s). Follow the -> hints above."
    Write-Host $summary -ForegroundColor Red
} elseif ($script:NWarn -gt 0) {
    $summary = "Ready, with $($script:NWarn) warning(s) worth a look."
    Write-Host $summary -ForegroundColor Yellow
} else {
    $summary = 'All good: your computer is ready for the course.'
    Write-Host $summary -ForegroundColor Green
}
Add-Line ''; Add-Line $summary

if (-not $checkOnly) {
    Write-Host ''
    Write-Host 'Next: ' -ForegroundColor White -NoNewline
    Write-Host 'load the tools into this terminal with:  ' -NoNewline
    Write-Host '. $HOME\ai-eng\env.ps1' -ForegroundColor White
    Write-Host '      Do the same in each new terminal you use for the course. Closing the terminal unloads them.'
    if ($codeAdded) { Write-Host "      For the 'code' command: $restartHint." }
    Write-Host '      Check everything at any time:  powershell -ExecutionPolicy Bypass -File $HOME\ai-eng\setup.ps1 -Check'
}

$text = $script:Report -join [Environment]::NewLine
$saved = $false
if (Test-Path -LiteralPath $AiEng) {
    try { Set-Content -LiteralPath $ReportFile -Value $text -Encoding UTF8 -ErrorAction Stop; $saved = $true } catch { $saved = $false }
}
if ($script:NFail -gt 0 -or $script:NWarn -gt 0) {
    $copied = $false
    if ($doCopy) { try { Set-Clipboard -Value $text -ErrorAction Stop; $copied = $true } catch { $copied = $false } }
    Write-Host ''
    if ($copied) { Write-Host 'Stuck? A report has been copied: paste it into the course help channel.' }
    elseif ($saved) { Write-Host "Stuck? Share the report in $ReportFile in the course help channel." }
}

if ($script:NFail -gt 0) { exit 1 } else { exit 0 }