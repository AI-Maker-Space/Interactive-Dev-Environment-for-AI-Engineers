<p align = "center" draggable=”false” ><img src="https://github.com/AI-Maker-Space/LLM-Dev-101/assets/37101144/d1343317-fa2f-41e1-8af1-1dbb18399719" 
     width="200px"
     height="auto"/>
</p>


## <h1 align="center" id="heading">:wave: Interactive Dev Environment (IDE) for AI Engineers </h1>

<p align="center">
  <img src="images/ai_engineer_at_workstation.jpg" alt="AI Engineer Setting Up Dev Env" width="300" />
</p>

### <h3 align="center"> Getting Started 🏗️ Building, 🚢 Shipping, and 🚀 Sharing Production LLM Application!!

🛣️ Welcome to the beginning of your journey to become an AI Engineer! 

This tutorial is designed to guide you through the process of setting up your Interactive Development Environment (IDE) to align with best-practices at [The LLM Edge](https://newsletter.aimakerspace.io/)!

### 🤖 AI Editors Supported 
* [Cursor (Recommended as best-practice tool)](https://github.com/getcursor/cursor)
* [Visual Studio Code](https://github.com/microsoft/vscode)
* 🆚 Watch [🪄 The Wiz walkthrough the key features of Cursor](https://www.youtube.com/live/RNIFvvvETM4?si=fjo1MWJQAq6UqzMt&t=1589) and what makes it different from VS Code)

Note: [Anysphere's Cursor](https://www.cursor.com/) is a just a fork of VS Code (like [Codeium's Windsurf](https://windsurf.com/) and other competitors). 


### 🏗️ The Simplest Stack
* Version Control: [Git](https://git-scm.com/)
* Command Line Interface (CLI): Shell for Unix-like OS
* Package/Env Management: [uv](https://github.com/astral-sh/uv)
* Python Notebooks: [Jupyter](https://jupyter.org/)
* Code Editor: [Cursor](https://github.com/getcursor/cursor) (or VS Code) (Note: Cursor is just a fork of VS Code)

### 🖥️ Operating Systems Supported (start [here](https://github.com/AI-Maker-Space/Interactive-Dev-Environment-for-LLM-Development?tab=readme-ov-file#rocket-lets-get-started))
* Windows
* Linux (Debian/Ubuntu)
* macOS Intel
* macOS Apple Silicon

<p></p>

## :hammer_and_wrench: Basic Concepts and Code

We will be using a few core tools in our stack such as a `terminal`, `Command Line Interface (CLI)`, `git`, `uv`, and `pip`.
<details>
<summary>Terminal and Command Line Interface </summary>

We must use both terminal and a Command Line Interface (CLI) to develop AI applications with open-source tools. This is true regardless of our operating system.

A terminal is a software application like macOS Terminal or Windows Terminal that gives you a window where you type text-based commands and receive text-based output.

A Command Line Interace (CLI) refers to the environment or shell (e.g., Bash, Zsh, PowerShell, etc.) that interprets your text commands. The CLI is the program that actually runs commands and processes input/output; it just happens to run inside a terminal application (or emulator).

Here is a quick review of some terminal commands that you  should make sure you know! It's important to understand both syntax and what they do! 

| Command      | Stands For |  Description |
| ----------- | ----------- | -------------|
| `ls`      | long listing       | lists all files and directories in the present working directory |
| `ls -a`  | long listing all   |  lists hidden files as well |
| `cd {dirname}`      | change directory       | to change to a particular directory |
| `cd ~`   | change directory home        | navigate to HOME directory |
| `cd ..`      | change directory up       | move one level up |
| `cat {filename}`   | concatenate        | displays the file content |
| `sudo`      | superuser       | allows regular users to run programs with the security privileges of the superuser or root |
| `mv {filename} {newfilename}`   | move        | renames the file to new filename |
| `clear`      | clear       | clears the terminal screen |
| `mkdir {dirname}`   | make directory        | create new directory in present working directory or at specified path |
| `rm {filename}`   | remove        | remove file with given filename |
| `touch {filename}.{ext}`   | touch        | create new empty file |
| `rmdir {dirname}`   | remove directory        | deletes a directory |
| `ssh {username}@{ip-address} or {hostname}`   | secure shell        | login into a remote Linux machine using SSH |

</details>

<details>
<summary>Git</summary>

Git is a free and open source distributed version control system designed to handle everything from small to very large projects. These are the commands we will be using with `git`:

`git clone` -> clone a remote repository to your local computer

`git add` -> add files to a commit

`git commit -m {message}` -> commit changes with a message

`git push` -> push commit to remote repository
</details>

<details>
<summary>uv & Pip</summary>

uv is an extremely fast Python package manager and virtual environment management tool, written in Rust. uv aims to be a drop-in replacement for pip and pip-tools, providing significantly improved performance. We will use `uv` to manage both our package installations and virtual environments.

Some commands we will use in this lesson when it comes to `uv` and `pip`:

`uv venv .venv -p 3.11` -> This creates a virtual environment with Python 3.11. A virtual environment is a Python environment such that the Python interpreter, libraries, and scripts installed into it are isolated from those installed on other environments and any libraries installed on the system. So basically, this allows you to keep all your project's code/dependencies/libraries separated from other projects.

`source .venv/bin/activate` -> This activates the virtual environment for your current terminal session.

`uv pip install numpy pandas matplotlib jupyter openai huggingface_hub` -> This installs the six packages mentioned - `numpy`, `pandas`, `jupyter`, `matplotlib`, `openai`, and `huggingface_hub`. `numpy` is used for scientific computing, `pandas` is used for data analysis, `matplotlib` is used for data graphics. `jupyter` is discussed later in this tutorial in depth! `openai` is used to access OpenAI's GPT models through an API key. `huggingface_hub` is used to push our code and models to Huggingface and host it in a Huggingface Space.

</details>

<p></p>

## :rocket: Let's Get Started! 
Let's start off by setting up our environment!  Review the environment setup instructions for the local environment that you'll be using in this course.
<details>
  <summary>Windows</summary>


* Install [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install) using Powershell

```powershell
wsl --install
```
* Install [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab) (You can even make it your [default!](https://devblogs.microsoft.com/commandline/
windows-terminal-as-your-default-command-line-experience/))

* Install [Ubuntu](https://www.microsoft.com/en-us/p/ubuntu/9pdxgncfsczv?activetab=pivot:overviewtab)

* Make sure you've install the correct version with the command `wsl -l -v`
    
(If you find yourself getting stuck on the WSL2 install, [here](https://www.youtube.com/watch?v=VMZH9Pj2dXw&ab_channel=StefanRows) is a link to video instructions)

Give it a test drive! 

![WindowsTerminal](https://user-images.githubusercontent.com/72572922/160048214-37f08855-8b29-4c13-9d25-e0f69806f752.jpg)

Continue by installing the following tools using [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab) to setup your environment.

| Tool | Purpose | Command                                                                                           |
| :-------- | :-------- | :------------------------------------------------------------------------------------------------ |
| :snake: **uv** (installed in WSL2) | Python Package Manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` <br> `source ~/.bashrc` |
| :octocat: **Git** (installed in WSL2) | Version Control | `sudo apt update && sudo apt upgrade` <br> `sudo apt install git-all`   |
| :memo: **VS Code** (installed in Windows) | Development Environment | [Download](https://code.visualstudio.com/download) |
| :memo: **Cursor** | Development Environment | [Download](https://www.cursor.com/downloads) |

</details>

<details>
  <summary>Linux (Debian/Ubuntu)</summary>

Open terminal using <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd>. Enter the following commands in terminal to setup your environment.
| Tool | Purpose | Command                                                                                           |
| :-------- | :-------- | :------------------------------------------------------------------------------------------------ |
| :snake: **uv**  | Python Package Manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` <br> `source ~/.bashrc` |
| :octocat: **Git**  | Version Control | `sudo apt update && sudo apt upgrade` <br> `sudo apt install git-all`   |
| :memo: **VS Code** | Development Environment | [Download](https://code.visualstudio.com/download) |
| :memo: **Cursor** | Development Environment | [Download](https://www.cursor.com/downloads) |

</details>

<details>
  <summary>macOS Intel</summary>

To get started, we need to download the MacOS package manager, <strong>Homebrew</strong> :beer:, so that we can download the tools we'll be using in the course. If you don't already have Homebrew installed, run the following commands:

1. Open terminal using <kbd>⌘</kbd>+<kbd>Space</kbd> and type `terminal`.

2. Install Homebrew using the command below, following the command prompts:

    `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` 

3. Update Homebrew (This may take a few minutes)

    `git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow`

    `git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch`
     
4. Install the `wget` command to continue following along
     `brew install wget`

Enter the following commands in terminal to setup your environment.

| Tool | Purpose | Command                                                                                           |
| :-------- | :-------- | :------------------------------------------------------------------------------------------------ |
| :snake: **uv**  | Python Package Manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` <br> `source ~/.bashrc` |
| :octocat: **Git**  | Version Control | `brew install git`   |
| :memo: **VS Code** | Development Environment | [Download](https://code.visualstudio.com/download) |
| :memo: **Cursor** | Development Environment | [Download](https://www.cursor.com/downloads) |

</details>

<details>
  <summary>macOS Apple Silicon</summary><br>

To get started with uv on Apple Silicon, we'll install it directly with our terminal.

Open terminal using <kbd>⌘</kbd>+<kbd>Space</kbd> and type `terminal`. Enter the following commands in terminal to setup your environment.

First, let's install Homebrew if you don't already have it installed:

1. Install Homebrew using the command below, following the command prompts:

    `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` 

2. Update Homebrew (This may take a few minutes)

    `git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow`

    `git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch`
     
3. Install the `wget` command to continue following along
     `brew install wget`

4. Install the `xcode-select` command-line utilities by typing the following command in the terminal

    `xcode-select --install`

Now let's install uv and other tools:

| Tool | Purpose | Command                                                                                           |
| :-------- | :-------- | :------------------------------------------------------------------------------------------------ |
| :snake: **uv**  | Python Package Manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| :octocat: **Git**  | Version Control | `brew install git`   |
| :memo: **VS Code** | Development Environment | [Download](https://code.visualstudio.com/download) |
| :memo: **Cursor** | Development Environment | [Download](https://www.cursor.com/downloads) |

</details>


<p></p>


## 🧑‍💻 Let's configure our Cursor (or VS Code) environment!

<details>
  <summary>Install the IntelliCode Extension</summary>

  IntelliCode is an AI-powered code completion extension to boost coding productivity. :sunglasses:

  1. Click the `Extensions` <img src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/f17d8f45-f174-4b9b-be92-8f1e85d8a77b" width=30px/> tab in the navigation panel on the left side of Cursor (or VS Code). 

  2. Type "IntelliCode" in the search bar.

  3. Click `install` <img src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/4c06f2a7-d7c3-4c59-b656-82170518cbeb" width=30px/> on the <ins><strong>Microsoft IntelliCode Extension</strong></ins>

</details>

<details>
  <summary>Install the Python and Jupyter Notebook Extensions</summary>

  1. Click the `Extensions` <img src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/f17d8f45-f174-4b9b-be92-8f1e85d8a77b" width=30px/> tab on the left side of the window.

  2. Type "Python" in the search bar.

  3. Click `Install` <img src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/4c06f2a7-d7c3-4c59-b656-82170518cbeb" width=30px/>  on the <ins><strong>Python</strong></ins> extension

  4. Then, type "Jupyter" in the search bar.

  5. Click `Install` <img src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/4c06f2a7-d7c3-4c59-b656-82170518cbeb" width=30px/>  on the <ins><strong>Microsoft Jupyter Notebook Extension</strong></ins>

</details>

<details>
  <summary>Set the Python Interpreter</summary>

  1. Open Cursor (or VS Code) and click on `New File...`

  3. Open the Command Pallette 
    <strong>(Mac: </strong></ins> <kbd>Shift</kbd><kbd>⌘</kbd>+<kbd>P</kbd> 
    ,<strong> Windows: </strong></ins> <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>)

  4. Type "Python" in the search bar.

  5. Click on `New Python File`

  6. Open the Command Pallette again.  Can you remember the shortcut?  If    not, see #2 above again.

  7. Type "Python Interpreter".

  8. Click on `Python: Select Interpreter`

  9. Select the Python environment that was created by uv.
  
  <p align = "center" draggable="false">
  <img src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/d95ff119-2c97-4bf8-9133-1bf167f61f6e"> 
  </p>

  9. Now you're ready to start coding!

</details>

<p> </p>


## 🐳 Setting up Docker Desktop and Compose

<details>
  <summary>Windows</summary>



**👉 [💿 Download Docker](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)** 👈

1. Double-click **Docker Desktop Installer.exe** to run the installer.

2. When prompted, ensure the **Use WSL 2 instead of Hyper-V** option on the Configuration page is selected or not depending on your choice of backend.

   If your system only supports one of the two options, you will not be able to select which backend to use.

3. Follow the instructions on the installation wizard to authorize the installer and proceed with the install.

4. When the installation is successful, select **Close** to complete the installation process.

5. If your admin account is different to your user account, you must add the user to the **docker-users** group. Run **Computer Management** as an **administrator** and navigate to **Local Users and Groups** > **Groups** > **docker-users**. Right-click to add the user to the group.
   Sign out and sign back in for the changes to take effect.
   
</details>



<details>
  <summary>Ubuntu</summary>

To install Docker Desktop successfully, you must:

- Meet the [system requirements](https://docs.docker.com/engine/install/ubuntu/#prerequisites)
- Have a 64-bit version of either Ubuntu Jammy Jellyfish 22.04 (LTS) or Ubuntu Impish Indri 21.10.
  Docker Desktop is supported on `x86_64` (or `amd64`) architecture.
- For non-Gnome Desktop environments, `gnome-terminal` must be installed:
  ```console
  $ sudo apt install gnome-terminal
  ```

1.  Update the `apt` package index and install packages to allow `apt` to use a
    repository over HTTPS:

    ```console
    $ sudo apt-get update
    $ sudo apt-get install ca-certificates curl gnupg
    ```

2.  Add Docker's official GPG key:

    ```console
    $ sudo install -m 0755 -d /etc/apt/keyrings
    $ curl -fsSL {{% param "download-url-base" %}}/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $ sudo chmod a+r /etc/apt/keyrings/docker.gpg
    ```

3.  Use the following command to set up the repository:

    ```console
    $ echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] {{% param "download-url-base" %}} \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```

4. Update the `apt` package index:

   ```console
   $ sudo apt-get update
   ```


5. Download Docker Desktop
   
     ``` bash
     wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.22.1-amd64.deb
     ```

6. Install the package with apt as follows:
     ```bash
     $ sudo apt-get update
     $ sudo apt-get install ./docker-desktop-4.22.1-amd64.deb
     ```
     
7. Launch Docker Desktop
     ```bash
          systemctl --user start docker-desktop
     ```
     
   > **Note**
   >
   > At the end of the installation process, `apt` displays an error due to installing a downloaded package. You
   > can ignore this error message.
   >
   > ```
   > N: Download is performed unsandboxed as root, as file '/home/user/Downloads/docker-desktop.deb' couldn't be accessed by user '_apt'. - pkgAcquire::Run (13: Permission denied)
</details>



<details>
  <summary>macOS (Intel and Apple Silicon)</summary>

**👉 [💿 Download Docker](https://desktop.docker.com/mac/main/arm64/Docker.dmg)** 👈

1. Double-click `Docker.dmg` to open the installer, then drag the Docker icon to
    the **Applications** folder.


2. Double-click `Docker.app` in the **Applications** folder to start Docker.

3. The Docker menu ({{< inline-image src="images/whale-x.svg" alt="whale menu" >}}) displays the Docker Subscription Service Agreement.

    {{< include "desktop-license-update.md" >}}

4. Select **Accept** to continue. 

   Note that Docker Desktop won't run if you do not agree to the terms. You can choose to accept the terms at a later date by opening Docker Desktop.

   For more information, see [Docker Desktop Subscription Service Agreement](https://www.docker.com/legal/docker-subscription-service-agreement). We recommend that you also read the [FAQs](https://www.docker.com/pricing/faq).
5. From the installation window, select either: 
   - **Use recommended settings (Requires password)**. This let's Docker Desktop automatically set the necessary configuration settings. 
   - **Use advanced settings**. You can then set the location of the Docker CLI tools either in the system or user directory, enable the default Docker socket, and enable privileged port mapping. See [Settings](../settings/mac.md#advanced), for more information and how to set the location of the Docker CLI tools.
6. Select **Finish**. If you have applied any of the above configurations that require a password in step 5, enter your password to confirm your choice.
</details>




## 🔑 Setting Up Keys and Tokens

<details>



     
  <summary>Generating a GitHub Access Token</summary>
     
**Create an account with GitHub [here](https://github.com/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home) if you do not have one.**

Navigate to [GitHub's Developer Token settings](https://github.com/settings/tokens).
Click on `Generate new token` > `Generate new token (classic)`
![Screenshot 2023-08-30 at 8 16 58 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/d6f57901-6e69-42e5-a22c-37b48ff6e3fc)

Give the token a description, set the expiration (we recommend 90 days), and check every box. When you're done, click `Generate token` at the bottom of the page. 

![Screenshot 2023-08-30 at 8 36 14 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/451bad7b-ec8a-4429-a5bb-8d0212d00f50)

Copy the access token and save it for later use. We will use this token to interact with GitHub. Please do not lose this access token or you will need to generate a new one.

![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/f98c9644-e44b-4fd3-8590-db513bef6360)

</details>


<details>
  <summary>Generating an OpenAI API key</summary>
     
**Create an account with OpenAI [here](https://platform.openai.com/signup) if you do not have one.**

Navigate to [OpenAI's API Developer settings](https://platform.openai.com/account/api-keys) and click on `+ Create new secrete key`.
![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/b6179d51-76ac-42a8-8304-39f8b5c9a8c8)

Name your key and click `Create secret key`
![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/be0ea05f-59d3-4d20-939d-b402e3d4bbb2)

Copy the key and save it for later use. We will use this key several times in deploying projects. Please do not lose this key or you will need to generate a new one

![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/cfaec5fa-5380-4aca-a6ae-6c14c8db6789)

We recommend your run through our [OpenAI Notebook](https://colab.research.google.com/drive/16Y67VozkGVErtrF3WQArpM52AOk5pBGu?usp=sharing#scrollTo=3qCKaH6vD-jZ) to learn how to utilize the OpenAI API.
</details>

<details>
  <summary>Generating a Claude API key</summary>

**Create an account with Claude AI (anthropic.com) [here](htttps://console.anthropic.com) if you do not have one.**

  Navigate to [Anthropic's Dashboard](https://console.anthropic.com/dashboard) and click on `Get API keys`
  _NOTE: If you have not purchased credits yet, it will require you to purchase at least $5.00 worth before continuing._
  ![Claude Actions](/images/claude_actions.png)

  Enter a key name (or accept the default) and click on `Create API Key`
  ![Claude Create API Key](/images/claude_create_api_key.png)

  Click the `Copy` button and save the key somewhere that is secure. We will use this key several times in deploying projects. As stated in the modal, _Keep a record of your API key, you wont be able to view it again._

![Claude Save API Key](/images/claude_save_api_key.png)

  If you want to test the api key first, copy the example code and paste it into a terminal. The results will look something like this:
  ![Claude API Key Test Results](/images/claude_api_key_test_results.png)

</details>

<details>
  <summary>Generating a Huggingface Access Token</summary>
     
**Create an account with Huggingface [here](https://huggingface.co/join) if you do not have one.**

Navigate to [Token settings](https://huggingface.co/settings/tokens) and click on `New token`.
![Screenshot 2023-08-29 at 6 16 12 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/8ec271de-4cb2-44b0-b6f8-ea354e2c42c2)

Name your access token, change the role to write, and click `Generate a token`
![Screenshot 2023-08-29 at 6 16 58 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/b9ae1590-1541-497d-a54a-1188438844b8)

Copy the token and save it for later use. We will use this token several times in deploying projects. If you lose this token, you can always go back to your token's page and view the token.

![Screenshot 2023-08-29 at 6 17 29 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/5fa285fa-d2ef-4308-b713-fb7384a53516)

Login to Huggingface using your terminal
``` bash
huggingface-cli login
```
![Screenshot 2023-08-29 at 6 13 23 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/31727145-8451-48bd-a560-9d92a8d4af3a)

After logging in, press `y` to add the token to credentials for git.
![Screenshot 2023-08-29 at 6 18 13 PM](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/5215d7eb-7a40-4e50-acf1-a5b7c5186a54)

</details>


## <img src="https://octodex.github.com/images/original.png" width=40px/> Let's Make Sure That GitHub is Ready to Roll!

<details>
  <summary>Github SSH Setup</summary>
  Secure Shell Protocol (SSH) provides a secure communication channel of an unsecured network.  Let's set it up!
  
  <p></p>

  1. Generate a Private/Public SSH Key Pair.
    
  ```console
  ssh-keygen -o -t rsa -C "your email address for github"
  ```

  2. Save file pair.  Default location `~/.ssh/id_rsa` is fine! 
  

  3. At the prompt, type in a secure passphrase.
  4. Copy the contents of the public key that we will share with GitHub. 

     * Mac: `pbcopy < ~/.ssh/id_rsa.pub` 

     * Windows (WSL): `clip.exe < ~/.ssh/id_rsa.pub`

     * Linux: `xclip -sel c < ~/.ssh/id_rsa.pub`
  
  5. Go to your GitHub account and go to `Settings`. 
  
  6. Under `Access`, click on the `SSH and GPG keys` tab on the left.

  ![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/5fb54f16-7279-49c4-bda3-2da36cbbc306)


  7. Click on the `New SSH Key` button.
  
  ![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/d5551c28-9d70-438c-b45d-43698384e3ff)

  
  8. Name the key, and paste the public key that you copied. Click the `Add SSH Key` button
  

  ![image](https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/8f7c4496-0e88-4058-9baf-73495322db8b)


</details>

<details>
  <summary>Viewing the Repositories</summary>

Login and click on the top right user icon, then go to `Your repositories`. 

<p align="center">
  <img width="648" alt="image" src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/18b766c6-ca91-4926-ad79-5fc101c3e6a0">
</p>
</details>


<details>
  <summary>Creating a New Repository</summary>

When viewing the respository page, click on `New` and proceed to create your repo.


<p align="center">
  <img width="335" alt="image" src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/dba31b88-0058-499c-a891-349de2d35279">
</p>
<hr>

**Filling Respository Details**

Create the repository by inputting the following:
* `Repo name`
* `Repo description`
* Make repo `public`
* Add a `README`
* Add `.gitignore` (Python template)
* Add `license` (choose MIT)

Then click `Create Repository`.

<p align="center">
  <img width="724" alt="image" src="https://github.com/AI-Maker-Space/LLMOps-Dev-101/assets/37101144/c20a19c1-548e-4576-b4b2-1d2ca99deae7">
</p>

</details>

<details>

<summary>Clone Your Repo</summary>

  1. Open your terminal and navigate to a place where you would like to make a directory to hold all your files for this class using the command `cd`. 


  ```console
  cd {directory name}
  ```
  
  2. Once there, make a top level directory using `mkdir`. 

  ```console
  mkdir {directory name}
  ```

  3. `cd` into it and make another directory called `code`. 

  ```console
  cd {directory name}
  ```

  ```console
  mkdir code
  ```

  4. `cd` into it and run your `git clone {your repo url}` command. 

  ```console
  cd code
  ```

  ```console
  git clone {your repo url}
  ```

</details>


<details>
  <summary>Adding The AI Makerspace Beyond-ChatGPT Content to Your Repo</summary>

  1. `cd` into your repo and check your remote git. 

  ```console
  cd {your repo name}
  ```

  ```console
  git remote -v
  ```

  At this point, you should just have access to your own repo with an origin branch with both fetch and push options.

  2. Let's setup our global configuration:

  ```console
  git config --global user.email "your email address"
  ```

  ```console
  git config --global user.name "your name"
  ```

  3. Let's add a local branch for development.

  ```console
  git checkout -b LocalDev
  ```

  You can change anything here in this branch!

  ```console
  git add .
  ```

  Commit the changes with the branch addition.

  ```console
  git commit -m "Adding a LocalDev branch."
  ```

  4. Let's push our local changes to our remote repo.

  ```console
  git checkout main
  ```

  ```console
  git merge LocalDev
  ```

  ```console
  git push origin main
  ```


5. Add the Beyond-ChatGPT (BC) repo as an extra remote repo:

  ```console
  git remote add BC git@github.com:AI-Maker-Space/Beyond-ChatGPT.git
  ```

  Let's check our remote repos:

  ```console
  git remote -v
  ```

  At this point, you should have access to both your own repo and the AI Maker Space repo and should see something like this:

  ```console
  BC    git@github.com:AI-Maker-Space/Beyond-ChatGPT.git (fetch)
  BC    git@github.com:AI-Maker-Space/Beyond-ChatGPT.git (push)
  origin git@github.com:ai-kadhim/TestRepo.git (fetch)
  origin git@github.com:ai-kadhim/TestRepo.git (push)
  ```

  Let's update our local repos:

  ```console
  git fetch --all
  ```

  Make a new branch for the Beyond-ChatGPT material (BCBranch).
  ```console
  git checkout --track -b BCBranch BC/main
  ```
  
  You should see something like this:
  
  ```console
  branch 'BCBranch' set up to track 'BC/main'.
  Switched to a new branch 'BCBranch'
  ```

  You can visually check whether you are in that branch:

  ```console
  git log --all --graph
  ```

  Now let's push our updated local repo to our remote repo!

  ```console
  git checkout main
  ```

  ```console
  git merge BCBranch --allow-unrelated-histories
  ```

  If there are any conflicts you'll need to resolve them.
  ```console
  git add .
  ```
  
  ```console
  git commit -m "message-here"
  ```
  
  ```console
  git push origin main
  ```

  From now on... after each release follow these steps to update your repo with new content:
  ```console
  git fetch --all
  git checkout BCBranch
  git merge --ff-only @{u}
  git add .
  git commit -m "branch is updated"
  git checkout main
  git merge BCBranch --allow-unrelated-histories
  ```

  You will be asked to add a comment about why this change is necessary --> add a message.
  
  ```console
  git push origin main
  ```
</details>

<p></p>

## <img src="https://jupyter.org/assets/homepage/main-logo.svg" width=40px/>  Bringing it all together with Jupyter Notebooks

<details>

  <summary>Activating Your Python Environment</summary>

  1. Now, let's activate the virtual environment we set up earlier with the command `uv venv activate`. If you were successful, you should see your virtual environment name in your terminal.

</details>

<details>

  <summary>Adding a Feature Branch</summary>

  Let's add a feature branch to our local repo.  Earlier, we showed you how to add a feature branch and content to your repo via the Terminal.  This time we are going to show you how to do it using the Cursor (or VS Code) GUI.  
  
  1. Click on the `main` <img src="images/vscode_main_branch.png" width=30px/> branch in the lower left side of the screen 

  2. You will then see a drop-down menu with some branch-level option commands.  Select the `Create a new branch` option.

  3. You will be prompted to enter the name for the branch.  Let's give our branch an informative name `feature-hello-world`.  The `feature` pre-fix is a common Git convention and let's our collaborators know what the purpose of the branch and the name of the feature.

  4. Now that we have a feature branch to work on, let's add some code to it!

</details>

<details>
  <summary>Hello World! - Part 1</summary>
  1. Next we will review some terminal commands and make some     additions to our repo.  Do these in your terminal where your     current working directory is your repo.

  * Check your current working directory: `pwd` 

  * Create a new file: `touch hello_world.py`

  * Create new directory: `mkdir app`

  * Move file to directory: `mv hello_world.py app/hello_world.py` 

  * Check that the move command worked: `cd app` and then `ls`, you
  should see your `hello_world.py` file

  * Lastly, lets clear our terminal screen: `clear`

  2. Click on the `Explorer` <img src="images/vscode_explorer_tab.png" width=30px/>  tab.

  3. Click on your `hello_world.py` file and type the following into the file:

  ```console
  print("hello world! let's do some ml ops!")
  ```

  4. Save. And now go to the integrated terminal by clicking `CTRL + ~`. In the terminal run your first program of the class by doing `cd app` -> `python hello_world.py`. Congrats, we are off to a great start!

</details>

<details>
  <summary>Hello World! - Part 2 - Notebook Edition</summary>

  1. Create a new file under `app` by clicking on the `Add file` button <img src="images/vscode_add_file.png" width=30px/> and let's name this file `hello_world.ipynb`. The `.ipynb` extension is a notebook extension which will allow you to interact with your code via a notebook in Cursor (or VS Code), instead of a vanilla Python file. You might need to select your kernel in the top right of the notebook file, if so, choose the one we created previously.
  
  2. In the first cell of `hello_world.ipynb` lets do our imports. 

      ```
      import pandas as pd
      import numpy as np
      import matplotlib.pyplot as plt
      ```

  3. Run the cell by either clicking the play button or by doing `CTRL + ENTER`. 

  4. Create a new cell and in that put the following code:
      ```
      np.random.seed(0)

      values = np.random.randn(100) # array of normally distributed random numbers
      s = pd.Series(values) # generate a pandas series
      s.plot(kind='hist', title='Normally distributed random values') # hist computes distribution
      plt.show()   
      ```
      
  5. Run the cell and you should see your histogram plot! Well done. 

  ![coding histogram](images/coding_histogram.jpeg)

  6. Now let's commit our code to our remote repository. This can be done one of two ways - either through the terminal or through Cursor's (or VS Code's) GUI. I'll explain the Cursor (or VS Code) way and but you can also choose to use the terminal method by making use of the commands demonstrated earlier.
    
  * Click `Source Control` <img src="images/vscode_source_control_tab.png" width=30px/>  on the left icon bar.

  * Add a message to your commit by typing in the message field. 

  * Click the check mark <img src="images/vscode_commit_check_mark.png" width=30px/> button under changes to add your files to this commit.  If you haven't saved your changes, you will be prompted to `Save All and Commit`.  Click `Save All and Commit`.
  
     
     
       <details>
       <summary>OPTIONAL: Manually staging individual files</summary>
          1. You can manually stage files by pressing the `+` button.
          
       ![image](https://i.imgur.com/2NnnSbc.png)
       </details>

  * Click the elipsis in `Source Control` <img src="images/vscode_ellipsis.png" width=30px/> ribbon and click `Push`.  You may also be prompted to `Sync Changes`.  This will do Pull and Push, which will fetch new changes to the code and push your updates as well.

  * You can then put in a pull request in GitHub <img src="images/github_pull_request.png" width=100px/>  to merge into the branch that you pulled from, in this case the main branch.  In real life, you would then review the code changes with another developer/team lead/supervisor and address any potential code conflicts.  
  
  <p align = "center" draggable=”false” ><img src="images/github_pull_request_compare.png" 
      width="500px"
      height="auto"/>
  </p>
  
</details>



## Build Your First LLM Application

Now that you've completed your IDE set-up, head on over to the [Beyond-ChatGPT](https://github.com/AI-Maker-Space/Beyond-ChatGPT) repository to build your first LLM application!
