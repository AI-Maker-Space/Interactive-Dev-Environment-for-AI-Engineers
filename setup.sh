#!/usr/bin/env bash
# =============================================================================
#  AI Engineer setup: macOS, Linux and WSL2              (Windows: setup.ps1)
#
#  Checks every tool the course needs and installs or fixes only what's
#  missing. Anything it installs goes into ~/ai-eng, except Claude Code (its
#  installer always uses ~/.local/bin) and system packages: Git (Apple's
#  developer tools on a Mac), and on Linux curl, bubblewrap and socat.
#  Safe to run again at any time.
#
#  Nothing is added to your shell profile, so the tools are only there when
#  you ask for them: load them into a terminal with
#    source ~/ai-eng/env.sh
#  and closing that terminal unloads them. The one exception is VS Code's
#  `code` command on a Mac, which goes in your profile so every terminal has it.
#
#  Run with:
#    bash ~/ai-eng/setup.sh            check, and fix what's missing
#    bash ~/ai-eng/setup.sh --check    check only: change nothing
#
#  Options:
#    --check        Report only; change nothing
#    --tools-only   Skip the Git name/email and GitHub SSH steps
#    --yes          Ask no questions; take the defaults (CI=true does the same)
#    --no-copy      Don't copy the report to the clipboard
#
#  Settings (environment variables):
#    PYTHON_VERSION=3.13  installed when there's no Python 3.12-3.14 already
#    NODE_VERSION=24      INSTALL_HOMEBREW=yes|no (Mac only)
#
#  Exit code: 0 when nothing failed (warnings are fine), 1 otherwise.
#  Must run on macOS's bash 3.2: no associative arrays, mapfile or ${x,,}.
# =============================================================================
set -uo pipefail   # deliberately no `set -e`: every step reports, then we carry on

AI_ENG="${AI_ENG_HOME:-$HOME/ai-eng}"
PYTHON_VERSION="${PYTHON_VERSION:-3.13}"   # installed only when no Python in the range below exists
PY_MIN="3.12"; PY_MAX="3.14"                # any version in this range (inclusive) is fine
PY_RANGE=">=$PY_MIN,<3.$(( ${PY_MAX#3.} + 1 ))"
NODE_VERSION="${NODE_VERSION:-24}"
NVM_VERSION="v0.40.8"
ENV_FILE="$AI_ENG/env.sh"
LOG="$AI_ENG/setup.log"
REPORT_FILE="$AI_ENG/setup-report.txt"
TILDE='~'; AI_ENG_SHOWN="${AI_ENG/#$HOME/$TILDE}"
ENV_SHOWN="$AI_ENG_SHOWN/env.sh"

# What the student's own terminal had before this script touched anything.
ORIG_PATH="$PATH"
ACTIVE=0; [ -n "${AI_ENG_HOME:-}" ] && ACTIVE=1

CHECK=0; TOOLS_ONLY=0; INTERACTIVE=1; COPY=1
if [ "${CI:-}" = "true" ]; then INTERACTIVE=0; COPY=0; fi
[ -t 0 ] || INTERACTIVE=0          # no keyboard attached: never wait for an answer
for arg in "$@"; do
  case "$arg" in
    --check)      CHECK=1 ;;
    --tools-only) TOOLS_ONLY=1 ;;
    --yes|-y)     INTERACTIVE=0 ;;
    --no-copy)    COPY=0 ;;
    -h|--help)    sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 2 ;;
  esac
done

# ============================================================================= output
if [ -t 1 ]; then
  GREEN=$'\033[32m'; CYAN=$'\033[36m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
  DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  GREEN=""; CYAN=""; YELLOW=""; RED=""; DIM=""; BOLD=""; RESET=""
fi

REPORT=""; N_FAIL=0; N_WARN=0; N_DONE=0
add() { REPORT+="$1"$'\n'; }
row() { # colour, tag, label, message
  printf '  %s%-6s%s %-16s %s\n' "$1" "$2" "$RESET" "$3" "$4"
  add "$(printf '%-6s %-16s %s' "$2" "$3" "$4")"
}
ok()    { row "$GREEN"  "[ OK ]" "$1" "$2"; }
done_() { row "$CYAN"   "[DONE]" "$1" "$2"; N_DONE=$((N_DONE + 1)); }
info()  { row "$DIM"    "[ -- ]" "$1" "$2"; }
warn()  { row "$YELLOW" "[WARN]" "$1" "$2"; N_WARN=$((N_WARN + 1)); }
fail()  { row "$RED"    "[FAIL]" "$1" "$2"; N_FAIL=$((N_FAIL + 1)); }
hint()  { printf '         %s-> %s%s\n' "$DIM" "$1" "$RESET"; add "         -> $1"; }
say()   { printf '         %s%s...%s\n' "$DIM" "$1" "$RESET"; }
section() { printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"; add ""; add "## $1"; }

have() { command -v "$1" >/dev/null 2>&1; }
log()  { [ -d "$AI_ENG" ] && printf '\n=== %s  %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; return 0; }

# Runs a command with its output going to the log. On failure, shows the end of it.
run_logged() {
  local start
  log "$*"
  start=$(($(wc -l <"$LOG") + 1))
  if "$@" >>"$LOG" 2>&1; then return 0; fi
  printf '%s' "$DIM"; tail -n "+$start" "$LOG" | tail -n 8 | sed 's/^/         | /'; printf '%s' "$RESET"
  return 1
}

ask_yn() { # question, default (y|n). Returns 0 for yes.
  local answer
  if [ "$INTERACTIVE" -eq 0 ]; then [ "$2" = y ]; return; fi
  printf '\n  %s ' "$1"; read -r answer || answer=""
  case "${answer:-$2}" in [Yy]*) return 0 ;; *) return 1 ;; esac
}
ask_text() { # prompt -> answer on stdout
  local answer
  printf '  %s ' "$1" >&2; read -r answer || answer=""
  printf '%s' "$answer"
}

copy_to_clipboard() {
  local clip
  for clip in pbcopy clip.exe wl-copy "xclip -selection clipboard"; do
    # shellcheck disable=SC2086  # $clip may hold a command plus its options
    if have "${clip%% *}" && printf '%s' "$1" | $clip >/dev/null 2>&1; then return 0; fi
  done
  return 1
}

open_url() {
  if [ "$OS" = Darwin ]; then open "$1" >/dev/null 2>&1
  elif [ "$IS_WSL" -eq 1 ] && have cmd.exe; then cmd.exe /c start "" "$1" >/dev/null 2>&1
  elif have xdg-open; then xdg-open "$1" >/dev/null 2>&1
  else return 1; fi
}

# ============================================================================= where are we?
OS="$(uname -s)"; ARCH="$(uname -m)"; IS_WSL=0
case "$OS" in
  Darwin) OS_NAME="macOS $(sw_vers -productVersion 2>/dev/null)" ;;
  Linux)
    # shellcheck disable=SC1091
    OS_NAME="$( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || echo Linux)"
    if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=1; OS_NAME="$OS_NAME (WSL2)"; fi ;;
  *) echo "This script is for macOS and Linux. On Windows, use setup.ps1."; exit 2 ;;
esac

if [ "${TERM_PROGRAM:-}" = "vscode" ]; then
  TERMINAL="VS Code"
  RESTART="Quit VS Code completely (Mac: Cmd+Q, otherwise close every VS Code window) and open it again"
elif [ "${TERMINAL_EMULATOR:-}" = "JetBrains-JediTerm" ]; then
  TERMINAL="JetBrains IDE"
  RESTART="Quit the IDE completely (File > Exit, or Cmd+Q on Mac) and open it again"
else
  TERMINAL="${TERM_PROGRAM:-unknown}"
  RESTART="Close this terminal window and open a new one"
fi

case "$(basename "${SHELL:-bash}")" in
  zsh)  PROFILES="$HOME/.zshrc" ;;
  bash) if [ "$OS" = Darwin ]; then PROFILES="$HOME/.bash_profile $HOME/.bashrc"; else PROFILES="$HOME/.bashrc"; fi ;;
  *)    PROFILES="$HOME/.profile" ;;
esac
PROFILES_SHOWN="${PROFILES//$HOME/$TILDE}"
CODE_MARK="# AI Engineer setup: VS Code 'code' command"
# Older versions of this setup loaded env.sh from the profile automatically.
OLD_HOOK="$ENV_FILE\"  # AI Engineer setup"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

RERUN="Run the setup again (without --check): it fixes what's missing"
LOGHINT="Details are in $LOG. Run the setup again; if it fails the same way, share that file"

# Installs Linux packages with whichever package manager the system has.
install_packages() {
  local pm=""
  for pm in apt-get dnf zypper pacman; do have "$pm" && break; pm=""; done
  if [ -z "$pm" ]; then return 1; fi
  if [ -n "$SUDO" ]; then
    have sudo || return 1
    if ! sudo -n true 2>/dev/null; then
      echo "         Your computer password is needed to install $*. (It won't show as you type.)"
      sudo -v || return 1
    fi
  fi
  case "$pm" in
    apt-get) run_logged $SUDO apt-get update -qq && run_logged $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
    dnf)     run_logged $SUDO dnf install -y -q "$@" ;;
    zypper)  run_logged $SUDO zypper --non-interactive install "$@" ;;
    pacman)  run_logged $SUDO pacman -S --noconfirm --needed "$@" ;;
  esac
}

# A program installed in a standard place but missing from this terminal's PATH
# almost always means the terminal (or the editor around it) predates the setup.
find_hidden() {
  local cmd="$1" dir f
  for dir in "$AI_ENG/bin" "$HOME/.local/bin" /opt/homebrew/bin /usr/local/bin; do
    if [ -x "$dir/$cmd" ]; then echo "$dir/$cmd"; return 0; fi
  done
  for f in "$AI_ENG"/nvm/versions/node/*/bin/"$cmd" "$HOME"/.nvm/versions/node/*/bin/"$cmd"; do
    if [ -x "$f" ]; then echo "$f"; return 0; fi
  done
  return 1
}
missing() { # label, command
  local where
  if where="$(find_hidden "$2")"; then
    warn "$1" "installed ($where), but this terminal can't see it"
    hint "$RESTART"
  else
    fail "$1" "not installed"
    hint "$RERUN"
  fi
}

# nvm is a shell function, and it isn't written for `set -u`.
NVM_LOADED=0
load_nvm() {
  local dir
  for dir in "${NVM_DIR:-}" "$AI_ENG/nvm" "$HOME/.nvm"; do
    if [ -n "$dir" ] && [ -s "$dir/nvm.sh" ]; then
      export NVM_DIR="$dir"
      set +u
      # shellcheck disable=SC1091
      . "$NVM_DIR/nvm.sh" --no-use >/dev/null 2>&1
      set -u
      if type nvm >/dev/null 2>&1; then NVM_LOADED=1; return 0; fi
    fi
  done
  return 1
}
nvm_() { set +u; nvm "$@"; local rc=$?; set -u; return $rc; }
major() { local v="${1#v}"; echo "${v%%.*}"; }
older_than() { # version, wanted major. False for anything that isn't a version (e.g. "system").
  local m; m="$(major "$1")"
  case "$m" in ''|*[!0-9]*) return 1 ;; esac
  [ "$m" -lt "$2" ]
}

# ============================================================================= header
printf '%sAI Engineer setup%s %s(%s)%s\n' "$BOLD" "$RESET" "$DIM" \
  "$([ "$CHECK" -eq 1 ] && echo "check only: nothing will be changed" || echo "checks each item and fixes what's missing")" "$RESET"
printf '%sSystem: %s (%s) | Terminal: %s%s\n' "$DIM" "$OS_NAME" "$ARCH" "$TERMINAL" "$RESET"
add "AI Engineer setup $([ "$CHECK" -eq 1 ] && echo '--check')  $(date '+%Y-%m-%d %H:%M')"
add "System:   $OS_NAME ($ARCH)"
add "Terminal: $TERMINAL, shell ${SHELL:-unknown}"

# ============================================================================= base folder
section "Base folder (~/ai-eng)"

if [ "$CHECK" -eq 1 ]; then
  # Students who followed the step-by-step guide installed the tools themselves,
  # so there's no ~/ai-eng to find. That's fine: the tool checks below decide.
  if [ -f "$ENV_FILE" ]; then ok "Base folder" "$AI_ENG"
  else info "Base folder" "$AI_ENG_SHOWN not created (fine if you installed the tools yourself)"; fi
else
  mkdir -p "$AI_ENG/bin" "$AI_ENG/python"
  : >>"$LOG"
  log "setup started: $OS_NAME, $TERMINAL"
  cat >"$ENV_FILE" <<EOF
# Loads the AI Engineer tools into THIS terminal only:  source ~/ai-eng/env.sh
# Closing the terminal unloads them. Written by the AI Engineer setup and
# rewritten every time it runs, so put your own settings elsewhere.
AI_ENG_HOME="$AI_ENG"; export AI_ENG_HOME
if [ -x /opt/homebrew/bin/brew ]; then eval "\$(/opt/homebrew/bin/brew shellenv)"; fi
case ":\$PATH:" in *":\$HOME/.local/bin:"*) ;; *) PATH="\$HOME/.local/bin:\$PATH" ;; esac
case ":\$PATH:" in *":\$AI_ENG_HOME/bin:"*) ;; *) PATH="\$AI_ENG_HOME/bin:\$PATH" ;; esac
export PATH
UV_PYTHON_INSTALL_DIR="\$AI_ENG_HOME/python"; export UV_PYTHON_INSTALL_DIR
if [ -s "\$AI_ENG_HOME/nvm/nvm.sh" ]; then
  NVM_DIR="\$AI_ENG_HOME/nvm"; export NVM_DIR
  . "\$NVM_DIR/nvm.sh"
  if [ -n "\${BASH_VERSION:-}" ] && [ -s "\$NVM_DIR/bash_completion" ]; then . "\$NVM_DIR/bash_completion"; fi
fi
EOF
  cat >"$AI_ENG/README.txt" <<EOF
This folder holds the tools installed by the AI Engineer setup.

  bin/          uv (Python package manager)
  python/       Python versions installed by uv
  nvm/          nvm and Node.js versions (only if you didn't already have nvm)
  env.sh        loads all of the above into a terminal:  source ~/ai-eng/env.sh
  setup.sh      run again at any time: bash ~/ai-eng/setup.sh  (or --check)
  setup.log     what the last runs did, for troubleshooting

Nothing loads these tools automatically: run "source ~/ai-eng/env.sh" in each
terminal where you want them. Closing the terminal unloads them again.

Claude Code is the exception to the folder: its installer always uses
~/.local/bin (env.sh adds that too).

To remove everything: delete this folder. On a Mac, also delete the line
ending in "$CODE_MARK" from $PROFILES_SHOWN
if you no longer want the 'code' command.
EOF
  ok "Base folder" "$AI_ENG"
fi

# Profiles that an older version of this setup made load env.sh automatically
OLD_HOOKED=""
for p in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  grep -qsF "$OLD_HOOK" "$p" && OLD_HOOKED="${OLD_HOOKED:+$OLD_HOOKED }$p"
done
if [ -n "$OLD_HOOKED" ]; then
  if [ "$CHECK" -eq 1 ]; then
    warn "Shell profile" "${OLD_HOOKED//$HOME/$TILDE} still loads env.sh automatically (older setup)"
    hint "$RERUN"
  else
    for p in $OLD_HOOKED; do
      cp "$p" "$p.before-ai-eng-update"
      grep -vF "$OLD_HOOK" "$p.before-ai-eng-update" >"$p"   # rewrites in place, keeping the file's permissions
    done
    done_ "Shell profile" "${OLD_HOOKED//$HOME/$TILDE} no longer loads env.sh automatically"
  fi
fi
# Older versions also linked 'code' into ~/ai-eng/bin; it now lives in the profile.
if [ "$CHECK" -eq 0 ] && [ -L "$AI_ENG/bin/code" ]; then rm -f "$AI_ENG/bin/code"; fi

if [ "$ACTIVE" -eq 1 ]; then
  ok "Tools loaded" "env.sh is active in this terminal"
elif [ "$CHECK" -eq 1 ] && [ -f "$ENV_FILE" ]; then
  info "Tools loaded" "not in this terminal. To use them: source $ENV_SHOWN"
fi

# From here on, the script runs with env.sh loaded: the same tools a student
# gets after "source ~/ai-eng/env.sh". This doesn't touch their own terminal.
if [ -f "$ENV_FILE" ]; then
  set +u
  # shellcheck disable=SC1090
  . "$ENV_FILE" >/dev/null 2>&1
  set -u
fi
NVM_LOADED=0; type nvm >/dev/null 2>&1 && NVM_LOADED=1
if [ "$CHECK" -eq 0 ]; then
  if ! have curl; then
    say "installing curl"
    install_packages curl || { fail "curl" "needed to download tools, and couldn't be installed"; exit 1; }
  fi
fi

# ============================================================================= tools
section "Tools"

# ---- Git. On a Mac it comes with Apple's developer tools; /usr/bin/git is only
# a stub that opens an install dialog until those are installed.
git_ok() {
  if [ "$OS" = Darwin ]; then xcode-select -p >/dev/null 2>&1 && have git; else have git; fi
}
if git_ok; then
  ok "Git" "$(git --version | awk '{print $3}')"
elif [ "$CHECK" -eq 1 ]; then
  if [ "$OS" = Darwin ]; then fail "Git" "Apple's developer tools are not installed"; hint "$RERUN"; else missing "Git" git; fi
elif [ "$OS" = Darwin ]; then
  echo "         A window will open: click Install, then Agree. It takes 5-15 minutes."
  xcode-select --install >/dev/null 2>&1
  printf '         Waiting for the install to finish'
  for _ in $(seq 1 180); do git_ok && break; printf '.'; sleep 10; done; echo
  if git_ok; then done_ "Git" "$(git --version | awk '{print $3}') installed"
  else fail "Git" "Apple's developer tools didn't finish installing"; hint "Finish the install window, then run the setup again"; fi
else
  say "installing Git"
  if install_packages git && have git; then done_ "Git" "$(git --version | awk '{print $3}') installed"
  else fail "Git" "couldn't be installed"; hint "$LOGHINT"; fi
fi

# ---- Homebrew (Mac only, optional: nothing in the setup needs it)
if [ "$OS" = Darwin ]; then
  BREW=""
  # First match wins: an Apple Silicon Homebrew beats a leftover Intel one in /usr/local.
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { BREW="$b"; break; }; done
  if [ -n "$BREW" ]; then
    ok "Homebrew" "$("$BREW" --version 2>/dev/null | awk 'NR==1{print $2}') (optional)"
  elif [ "$CHECK" -eq 1 ]; then
    info "Homebrew" "not installed (optional)"
  else
    want="${INSTALL_HOMEBREW:-}"
    if [ -z "$want" ]; then
      if ask_yn "Homebrew is optional: the course doesn't need it. Install it anyway? [y/N]" n; then want=yes; else want=no; fi
    fi
    if [ "$want" = yes ]; then
      echo "         Installing Homebrew. It asks for your computer password (it won't show as you type)."
      # Homebrew treats ANY value of NONINTERACTIVE (even 0) as "don't ask", so set it only when needed.
      brew_env=""; [ "$INTERACTIVE" -eq 0 ] && brew_env="NONINTERACTIVE=1"
      if env $brew_env /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        done_ "Homebrew" "installed"
      else
        fail "Homebrew" "install failed"; hint "Homebrew is optional: the rest of the setup doesn't need it"
      fi
    else
      info "Homebrew" "skipped (optional)"
    fi
  fi
fi

# ---- uv: Python's package and project manager
if have uv; then
  ok "uv" "$(uv --version | awk '{print $2}')"
elif [ "$CHECK" -eq 1 ]; then
  missing "uv" uv
else
  say "installing uv into ~/ai-eng/bin"
  if run_logged env UV_INSTALL_DIR="$AI_ENG/bin" UV_NO_MODIFY_PATH=1 INSTALLER_NO_MODIFY_PATH=1 \
       bash -c 'set -o pipefail; curl -LsSf https://astral.sh/uv/install.sh | sh' && have uv; then
    done_ "uv" "$(uv --version | awk '{print $2}') installed in ~/ai-eng/bin"
  else
    fail "uv" "couldn't be installed"; hint "$LOGHINT"
  fi
fi

# ---- Python: any version from 3.12 to 3.14 is fine. If there's none,
# uv installs $PYTHON_VERSION into ~/ai-eng/python.
py_version() { "$1" -c 'import sys; print(*sys.version_info[:3], sep=chr(46))' 2>/dev/null; }
if ! have uv; then
  info "Python" "not checked (needs uv)"
else
  PY_INSTALLED=0
  py="$(uv python find --no-project "$PY_RANGE" 2>/dev/null || true)"
  if [ -n "$py" ] && pyv="$(py_version "$py")" && [ -n "$pyv" ]; then
    ok "Python" "$pyv"
  elif [ -n "$py" ]; then
    warn "Python" "found at $py, but it didn't report its version"
    hint "Try running it: \"$py\" --version"
  elif [ "$CHECK" -eq 1 ]; then
    fail "Python" "no Python $PY_MIN-$PY_MAX installed"; hint "$RERUN"
  else
    say "installing Python $PYTHON_VERSION into ~/ai-eng/python"
    if run_logged uv python install "$PYTHON_VERSION" && py="$(uv python find --no-project "$PYTHON_VERSION" 2>/dev/null)"; then
      done_ "Python" "$(py_version "$py") installed in ~/ai-eng/python"
      PY_INSTALLED=1
    else
      fail "Python" "$PYTHON_VERSION couldn't be installed"; hint "$LOGHINT"
    fi
  fi

  # A default for new projects matters only when you've chosen one, or when
  # the setup had to install Python itself (so uv picks that one).
  pin="$(cd / && uv python pin --global 2>/dev/null | head -1)"
  case "$pin" in
    3.1[2-4]|3.1[2-4].*) ok "Default Python" "$pin" ;;
    [0-9]*)              info "Default Python" "$pin (your setting, kept)" ;;
    *)
      if [ "$PY_INSTALLED" -eq 1 ]; then
        if run_logged uv python pin --global "$PYTHON_VERSION"; then
          done_ "Default Python" "$PYTHON_VERSION for projects that don't choose their own"
        else
          warn "Default Python" "couldn't be set"; hint "$LOGHINT"
        fi
      fi ;;
  esac
fi

# ---- Node.js through nvm (or Volta/fnm, if that's what you already use)
MANAGER=""
if have volta; then MANAGER="Volta"; elif have fnm; then MANAGER="fnm"; fi
NODE_NEW=0
manager_hint() {
  case "$MANAGER" in
    Volta) hint "volta install node@$NODE_VERSION" ;;
    fnm)   hint "fnm install $NODE_VERSION && fnm default $NODE_VERSION" ;;
  esac
}

if [ -n "$MANAGER" ]; then
  info "nvm" "not used: your Node.js is managed by $MANAGER"
elif load_nvm; then
  ok "nvm" "$(nvm_ --version)"
elif [ "$CHECK" -eq 1 ]; then
  warn "nvm" "not installed, so projects can't choose their own Node.js version"; hint "$RERUN"
else
  say "installing nvm into ~/ai-eng/nvm"
  mkdir -p "$AI_ENG/nvm"
  if run_logged env NVM_DIR="$AI_ENG/nvm" PROFILE=/dev/null \
       bash -c "set -o pipefail; curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash" && load_nvm; then
    done_ "nvm" "$(nvm_ --version) installed in ~/ai-eng/nvm"
  else
    fail "nvm" "couldn't be installed"; hint "$LOGHINT"
  fi
fi

# Install Node through nvm only when there's no suitable Node already.
NODE_NOW="$(node --version 2>/dev/null || true)"
if [ "$CHECK" -eq 0 ] && [ "$NVM_LOADED" -eq 1 ] && { [ -z "$NODE_NOW" ] || older_than "$NODE_NOW" "$NODE_VERSION"; }; then
  if [ "$(nvm_ version "$NODE_VERSION")" = "N/A" ]; then
    say "installing Node.js $NODE_VERSION"
    if run_logged nvm_ install "$NODE_VERSION"; then NODE_NEW=1; fi
  fi
  if [ "$(nvm_ version "$NODE_VERSION")" != "N/A" ]; then
    default="$(nvm_ version default)"
    if [ "$default" = "N/A" ]; then
      nvm_ alias default "$NODE_VERSION" >>"$LOG" 2>&1
    elif older_than "$default" "$NODE_VERSION" &&
         ask_yn "Your default Node.js is $default. Switch the default to Node.js $NODE_VERSION? [Y/n]" y; then
      nvm_ alias default "$NODE_VERSION" >>"$LOG" 2>&1
    fi
    nvm_ use default >/dev/null 2>&1   # put the default Node on PATH for the rest of this run
  fi
fi

if have node; then
  v="$(node --version)"
  if ! older_than "$v" "$NODE_VERSION"; then
    if [ "$NODE_NEW" -eq 1 ]; then done_ "Node.js" "${v#v} installed"; else ok "Node.js" "${v#v}"; fi
  else
    warn "Node.js" "${v#v} is older than the course needs ($NODE_VERSION+)"
    if [ -n "$MANAGER" ]; then manager_hint
    elif [ "$CHECK" -eq 1 ]; then hint "$RERUN"
    else hint "nvm alias default $NODE_VERSION, then $RESTART"; fi
  fi
  if have npm; then ok "npm" "$(npm --version 2>/dev/null)"; else missing "npm" npm; fi
elif [ -n "$MANAGER" ]; then
  # Running the setup again won't help here: it leaves Volta/fnm in charge.
  fail "Node.js" "not installed; your Node.js versions are managed by $MANAGER"; manager_hint
elif [ "$CHECK" -eq 0 ] && [ "$NVM_LOADED" -eq 1 ]; then
  fail "Node.js" "$NODE_VERSION couldn't be installed"; hint "$LOGHINT"
else
  missing "Node.js" node
fi

# ---- Claude Code (its installer always uses ~/.local/bin)
if have claude; then
  ok "Claude Code" "$(claude --version 2>/dev/null | awk '{print $1}')"
elif [ "$CHECK" -eq 1 ]; then
  missing "Claude Code" claude
else
  say "installing Claude Code"
  if run_logged bash -c 'set -o pipefail; curl -fsSL https://claude.ai/install.sh | bash' && have claude; then
    done_ "Claude Code" "$(claude --version 2>/dev/null | awk '{print $1}') installed"
  else
    fail "Claude Code" "couldn't be installed"; hint "$LOGHINT"
  fi
fi

# Linux and WSL2: Claude Code's /sandbox needs bubblewrap and socat.
if [ "$OS" = Linux ]; then
  if have bwrap && have socat; then
    ok "Claude sandbox" "bubblewrap and socat present"
  elif [ "$CHECK" -eq 1 ]; then
    warn "Claude sandbox" "bubblewrap or socat missing, so /sandbox won't work"; hint "$RERUN"
  else
    say "installing bubblewrap and socat for Claude Code's /sandbox"
    if install_packages bubblewrap socat && have bwrap && have socat; then
      done_ "Claude sandbox" "bubblewrap and socat installed"
    else
      warn "Claude sandbox" "bubblewrap/socat couldn't be installed, so /sandbox won't work"; hint "$LOGHINT"
    fi
  fi
fi

# ---- VS Code's `code` command (VS Code itself is installed by hand first).
# This is the one thing that goes in the shell profile, so every terminal has it.
VSCODE_APP=""
for app in "/Applications/Visual Studio Code.app" "$HOME/Applications/Visual Studio Code.app"; do
  [ -d "$app" ] && { VSCODE_APP="$app"; break; }
done
code_in_profile() { local p; for p in $PROFILES; do grep -qsF "$CODE_MARK" "$p" || return 1; done; return 0; }
PROFILE_CHANGED=0

if PATH="$ORIG_PATH" command -v code >/dev/null 2>&1; then
  ok "VS Code" "$(PATH="$ORIG_PATH" code --version 2>/dev/null | head -1) ('code' command works)"
elif [ -n "$VSCODE_APP" ] && code_in_profile; then
  if [ "$CHECK" -eq 1 ]; then
    warn "VS Code" "'code' is set up in $PROFILES_SHOWN, but this terminal opened before that"
    hint "Open a new terminal (Terminal > New Terminal)"
  else
    ok "VS Code" "'code' command set up in $PROFILES_SHOWN (new terminals)"
  fi
elif [ -n "$VSCODE_APP" ]; then
  if [ "$CHECK" -eq 1 ]; then
    warn "VS Code" "installed, but the 'code' command isn't set up"; hint "$RERUN"
  else
    for p in $PROFILES; do
      grep -qsF "$CODE_MARK" "$p" && continue
      [ -f "$p" ] && [ ! -f "$p.before-ai-eng" ] && cp "$p" "$p.before-ai-eng"
      # shellcheck disable=SC2016  # $PATH is meant literally: the profile expands it in each new terminal
      printf '\nexport PATH="$PATH:%s/Contents/Resources/app/bin"  %s\n' "$VSCODE_APP" "$CODE_MARK" >>"$p"
    done
    PROFILE_CHANGED=1
    done_ "VS Code" "'code' command added to $PROFILES_SHOWN (works in new terminals)"
  fi
elif [ "$TERMINAL" = "JetBrains IDE" ]; then
  info "VS Code" "not installed (fine: you're using a JetBrains IDE)"
elif [ "$IS_WSL" -eq 1 ]; then
  info "VS Code" "'code' not found: open this folder from VS Code on Windows (WSL extension)"
elif [ "$OS" = Darwin ] && [ -d "$HOME/Downloads/Visual Studio Code.app" ]; then
  warn "VS Code" "is still in Downloads"
  hint "Drag Visual Studio Code from Downloads into Applications, then run the setup again"
elif [ "${CI:-}" = "true" ]; then
  info "VS Code" "not installed (fine on a CI runner)"
else
  warn "VS Code" "not installed"
  hint "Install it from code.visualstudio.com (step 1 of the guide), then run the setup again"
fi

# ============================================================================= git and github
if [ "$TOOLS_ONLY" -eq 0 ]; then
  section "Git and GitHub"

  if ! have git; then
    info "Git identity" "not checked (needs Git)"
  else
    name="$(git config --global user.name 2>/dev/null || true)"
    email="$(git config --global user.email 2>/dev/null || true)"
    if [ -n "$name" ] && [ -n "$email" ]; then
      ok "Git identity" "$name"
    elif [ "$CHECK" -eq 1 ]; then
      fail "Git identity" "name or email not set"; hint "$RERUN"
    elif [ "$INTERACTIVE" -eq 0 ]; then
      warn "Git identity" "name or email not set (needs your answer)"; hint "Run the setup again in a terminal"
    else
      echo
      echo "  Git labels your work with a name and email."
      tries=0
      while [ -z "$name" ] && [ "$tries" -lt 5 ]; do name="$(ask_text "Your name (e.g. Ana Silva):")"; tries=$((tries + 1)); done
      echo "  Tip: GitHub can give you a private email for this, so your real one stays hidden."
      echo "  Find it at github.com/settings/emails (it ends in @users.noreply.github.com)."
      tries=0
      until case "$email" in *?@?*.?*) true ;; *) false ;; esac || [ "$tries" -ge 5 ]; do
        email="$(ask_text "Email for your work:")"; tries=$((tries + 1))
      done
      case "$email" in *?@?*.?*) email_ok=1 ;; *) email_ok=0 ;; esac
      if [ -n "$name" ] && [ "$email_ok" -eq 1 ] &&
         git config --global user.name "$name" && git config --global user.email "$email"; then
        done_ "Git identity" "set ($name)"
      else
        fail "Git identity" "name or email not set"; hint "Run the setup again and answer both questions"
      fi
    fi
    # Quietly match GitHub's default branch name, unless you've chosen one.
    if [ "$CHECK" -eq 0 ] && [ -z "$(git config --global init.defaultBranch 2>/dev/null)" ]; then
      git config --global init.defaultBranch main
    fi
  fi

  # ---- SSH key, registered on GitHub
  KEY="$HOME/.ssh/id_ed25519"
  github_test() { # sets SSH_STATE (ok|denied|hostkey|network|other) and SSH_DETAIL
    local out opts="-o ConnectTimeout=10"
    # A fixing run may ask for a passphrase and record GitHub's identity; a check can't.
    if [ "$CHECK" -eq 1 ] || [ "$INTERACTIVE" -eq 0 ]; then opts="$opts -o BatchMode=yes"; fi
    if [ "$CHECK" -eq 0 ]; then opts="$opts -o StrictHostKeyChecking=accept-new"; fi
    # shellcheck disable=SC2086
    out="$(ssh -T $opts git@github.com 2>&1 </dev/null || true)"
    case "$out" in
      *"successfully authenticated"*) SSH_STATE=ok; SSH_DETAIL="$(printf '%s' "$out" | sed -n 's/^Hi \([^!]*\)!.*/\1/p')" ;;
      *"Host key verification failed"*) SSH_STATE=hostkey ;;
      *"Permission denied"*) SSH_STATE=denied ;;
      *"timed out"*|*"refused"*|*"Could not resolve"*) SSH_STATE=network ;;
      *) SSH_STATE=other; SSH_DETAIL="$(printf '%s' "$out" | head -1)" ;;
    esac
  }

  if ! have ssh; then
    fail "GitHub SSH" "ssh not found"
  else
    # Test whatever key is already there first (e.g. an id_rsa from the step-by-step
    # guide), so a key that already works doesn't get a redundant new one beside it.
    if [ -f "$KEY" ] || ls "$HOME"/.ssh/id_*.pub >/dev/null 2>&1; then github_test; else SSH_STATE=nokey; fi
    # Make a key only when there's none, or GitHub turned the existing ones down.
    # A network problem says nothing about the keys, so it never triggers a new one.
    if [ "$CHECK" -eq 0 ] && [ ! -f "$KEY" ] && { [ "$SSH_STATE" = nokey ] || [ "$SSH_STATE" = denied ]; }; then
      mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
      if ssh-keygen -t ed25519 -N "" -q -f "$KEY" -C "$(git config --global user.email 2>/dev/null || echo "$USER")" </dev/null; then
        done_ "SSH key" "created ~/.ssh/id_ed25519"
        github_test
      else
        fail "SSH key" "couldn't be created"
      fi
    fi
  fi

  if [ "$CHECK" -eq 0 ] && [ "${SSH_STATE:-}" = denied ] && [ "$INTERACTIVE" -eq 1 ] && [ -f "$KEY.pub" ]; then
    echo
    echo "  Now let GitHub know this computer is yours:"
    if copy_to_clipboard "$(cat "$KEY.pub")"; then
      echo "   1. Your computer's key has been copied."
    else
      echo "   1. Copy this whole line (your computer's key):"; echo; echo "      $(cat "$KEY.pub")"; echo
    fi
    echo "   2. In the GitHub page that opens (sign in first if asked):"
    echo "      Title: anything, e.g. 'My laptop'.  Key: paste.  Then click 'Add SSH key'."
    open_url "https://github.com/settings/ssh/new" || echo "      Open https://github.com/settings/ssh/new in your browser."
    for _ in 1 2 3; do
      printf '\n  Press Enter once you have added the key... '; read -r _ || break
      github_test
      [ "$SSH_STATE" = denied ] || break
      echo "  GitHub doesn't accept the key yet. Check it was saved, and wait a few seconds."
    done
    [ "$SSH_STATE" = ok ] && N_DONE=$((N_DONE + 1))
  fi

  case "${SSH_STATE:-}" in
    ok)      ok "GitHub SSH" "connected as $SSH_DETAIL" ;;
    nokey)   fail "GitHub SSH" "this computer has no SSH key yet"; hint "$RERUN" ;;
    hostkey) fail "GitHub SSH" "this computer hasn't connected to GitHub before"; hint "$RERUN" ;;
    denied)  fail "GitHub SSH" "GitHub doesn't know this computer's key yet"
             hint "If your key has a passphrase, test it with: ssh -T git@github.com"
             hint "$RERUN and follow the GitHub step" ;;
    network) fail "GitHub SSH" "can't reach github.com (network or firewall)"
             hint "Some networks block SSH. See TROUBLESHOOTING.md: 'SSH over port 443'" ;;
    other)   warn "GitHub SSH" "couldn't be tested: ${SSH_DETAIL:-unknown error}" ;;
  esac
fi

# ============================================================================= summary
echo
if [ "$N_FAIL" -gt 0 ]; then
  SUMMARY="$N_FAIL problem(s) to fix, $N_WARN warning(s). Follow the -> hints above."
  COLOUR="$RED"
elif [ "$N_WARN" -gt 0 ]; then
  SUMMARY="Ready, with $N_WARN warning(s) worth a look."
  COLOUR="$YELLOW"
else
  SUMMARY="All good: your computer is ready for the course."
  COLOUR="$GREEN"
fi
printf '%s%s%s\n' "$COLOUR$BOLD" "$SUMMARY" "$RESET"
add ""; add "$SUMMARY"

if [ "$CHECK" -eq 0 ]; then
  echo
  printf '%sNext:%s load the tools into this terminal with:  %ssource %s%s\n' "$BOLD" "$RESET" "$BOLD" "$ENV_SHOWN" "$RESET"
  echo "      Do the same in each new terminal you use for the course. Closing the terminal unloads them."
  if [ "$PROFILE_CHANGED" -eq 1 ]; then
    echo "      The 'code' command works in every terminal you open from now on."
  fi
  echo "      Check everything at any time:  bash $AI_ENG_SHOWN/setup.sh --check"
fi

SAVED=0; [ -d "$AI_ENG" ] && printf '%s' "$REPORT" >"$REPORT_FILE" 2>/dev/null && SAVED=1
if [ "$N_FAIL" -gt 0 ] || [ "$N_WARN" -gt 0 ]; then
  echo
  if [ "$COPY" -eq 1 ] && copy_to_clipboard "$REPORT"; then
    echo "Stuck? A report has been copied: paste it into the course help channel."
  elif [ "$SAVED" -eq 1 ]; then
    echo "Stuck? Share the report in $REPORT_FILE in the course help channel."
  fi
fi

[ "$N_FAIL" -eq 0 ]