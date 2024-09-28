#!/bin/bash

# Jalur instalasi DLP Validator
DLP_PATH="$HOME/vana-dlp-chatgpt"

# Memeriksa apakah skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Coba gunakan perintah 'sudo -i' untuk beralih ke root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Instal dependensi yang diperlukan
function install_dependencies() {
    echo "Menginstal dependensi yang diperlukan..."
    apt update && apt upgrade -y
    apt install -y curl wget jq make gcc nano git software-properties-common
}

# Instal Python 3.11 dan Poetry
function install_python_and_poetry() {
    echo "Menginstal Python 3.11..."
    add-apt-repository ppa:deadsnakes/ppa -y
    apt update
    apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

    echo "Memeriksa versi Python..."
    python3.11 --version

    echo "Menginstal Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bash_profile
    source $HOME/.bash_profile

    echo "Memeriksa instalasi Poetry..."
    poetry --version
}

# Instal Node.js dan npm
function install_nodejs_and_npm() {
    echo "Memeriksa apakah Node.js sudah terinstal..."
    if command -v node > /dev/null 2>&1; then
        echo "Node.js sudah terinstal, versi: $(node -v)"
    else
        echo "Node.js belum terinstal, menginstal sekarang..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi

    echo "Memeriksa apakah npm sudah terinstal..."
    if command -v npm > /dev/null 2>&1; then
        echo "npm sudah terinstal, versi: $(npm -v)"
    else
        echo "npm belum terinstal, menginstal sekarang..."
        apt-get install -y npm
    fi
}

# Instal PM2
function install_pm2() {
    echo "Memeriksa apakah PM2 sudah terinstal..."
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 sudah terinstal, versi: $(pm2 -v)"
    else
        echo "PM2 belum terinstal, menginstal sekarang..."
        npm install pm2@latest -g
    fi
}

# Klon repositori Vana DLP ChatGPT dan instal dependensi
function clone_and_install_repos() {
    echo "Mengklon repositori Vana DLP ChatGPT..."
    rm -rf $DLP_PATH
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git $DLP_PATH
    cd $DLP_PATH

    echo "Membuat dan mengaktifkan lingkungan virtual Python..."
    python3.11 -m venv myenv
    source myenv/bin/activate

    echo "Menginstal dependensi Poetry..."
    pip install poetry
    poetry install

    echo "Menginstal Vana CLI..."
    pip install vana
}

# Membuat dompet
function create_wallet() {
    echo "Membuat dompet..."
    vanacli wallet create --wallet.name default --wallet.hotkey default

    echo "Pastikan sudah menambahkan jaringan Vana Moksha Testnet di MetaMask."
    echo "Ikuti langkah manual berikut:"
    echo "1. URL RPC: https://rpc.moksha.vana.org"
    echo "2. ID Rantai: 14800"
    echo "3. Nama Jaringan: Vana Moksha Testnet"
    echo "4. Mata Uang: VANA"
    echo "5. Block Explorer: https://moksha.vanascan.io"
}

# Ekspor kunci pribadi
function export_private_keys() {
    echo "Mengekspor kunci pribadi Coldkey..."
    ./vanacli wallet export_private_key --wallet.name default --wallet.coldkey default

    echo "Mengekspor kunci pribadi Hotkey..."
    ./vanacli wallet export_private_key --wallet.name default --wallet.hotkey default

    # Konfirmasi cadangan
    read -p "Apakah Anda sudah mencadangkan kunci pribadi? (y/n) " backup_confirmed
    if [ "$backup_confirmed" != "y" ]; then
        echo "Silakan cadangkan frasa pemulihan terlebih dahulu sebelum melanjutkan skrip."
        exit 1
    fi
}

# Skrip lainnya tetap sama
