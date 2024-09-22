# Vana Node


## Prerequisites

Make sure your system is up to date before proceeding with the installation.

## Update and Upgrade
```bash
sudo apt update && sudo apt upgrade -y && sudo apt-get install git -y && sudo apt install unzip && sudo apt install nano
```
## Install Python 3.11
```bash
sudo apt install software-properties-common -y && sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 -y
```
## Install Poetry
'''bash
sudo apt install python3-pip python3-venv curl -y && curl -sSL https://install.python-poetry.org | python3 -
'''
-Export
'''bash
export PATH="$HOME/.local/bin:$PATH" && source ~/.bashrc
'''
## Install Node.js and npm
'''bash
https://fnm.vercel.app/install | bash  && source ~/.bashrc && fnm use --install-if-missing 22
'''
## Installing dependencies
'''bash
apt-get install nodejs -y && npm install -g yarn
'''
## Clone the repository Vana
'''bash
git clone https://github.com/vana-com/vana-dlp-chatgpt.git && cd vana-dlp-chatgpt
'''
## 

