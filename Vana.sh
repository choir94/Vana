#!/bin/bash

# Jalur pemasangan Validator DLP
DLP_PATH="$HOME/vana-dlp-chatgpt"

# Periksa apakah skrip dijalankan sebagai pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses pengguna root."
    echo "Coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan kembali skrip ini."
    exit 1
fi

# Menginstal dependensi yang diperlukan
function install_dependencies() {
    echo "Menginstal dependensi yang diperlukan..."
    apt update && apt upgrade -y
    apt install -y curl wget jq make gcc nano git software-properties-common
}

# Menginstal Python 3.11 dan Poetry
function install_python_and_poetry() {
    echo "Menginstal Python 3.11..."
    add-apt-repository ppa:deadsnakes/ppa -y
    apt update
    apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

    echo "Verifikasi versi Python..."
    python3.11 --version

    echo "Menginstal Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bash_profile
    source $HOME/.bash_profile

    echo "Verifikasi instalasi Poetry..."
    poetry --version
}

# Menginstal Node.js dan npm
function install_nodejs_and_npm() {
    echo "Periksa apakah Node.js sudah diinstal..."
    if command -v node > /dev/null 2>&1; then
        echo "Node.js sudah diinstal, versi: $(node -v)"
    else
        echo "Node.js belum diinstal, sedang menginstal..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi

    echo "Periksa apakah npm sudah diinstal..."
    if command -v npm > /dev/null 2>&1; then
        echo "npm sudah diinstal, versi: $(npm -v)"
    else
        echo "npm belum diinstal, sedang menginstal..."
        apt-get install -y npm
    fi
}

# Menginstal PM2
function install_pm2() {
    echo "Periksa apakah PM2 sudah diinstal..."
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 sudah diinstal, versi: $(pm2 -v)"
    else
        echo "PM2 belum diinstal, sedang menginstal..."
        npm install pm2@latest -g
    fi
}

# Mengkloning repositori Vana DLP ChatGPT dan menginstal dependensi
function clone_and_install_repos() {
    echo "Mengkloning repositori Vana DLP ChatGPT..."
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

    echo "Pastikan Anda telah menambahkan jaringan Vana Moksha Testnet di MetaMask."
    echo "Ikuti langkah-langkah berikut untuk menambahkannya secara manual:"
    echo "1. RPC URL: https://rpc.moksha.vana.org"
    echo "2. Chain ID: 14800"
    echo "3. Nama Jaringan: Vana Moksha Testnet"
    echo "4. Mata Uang: VANA"
    echo "5. Block Explorer: https://moksha.vanascan.io"
}

# Mengekspor kunci privat
function export_private_keys() {
    echo "Mengekspor kunci privat Coldkey..."
    ./vanacli wallet export_private_key --wallet.name default --wallet.coldkey default

    echo "Mengekspor kunci privat Hotkey..."
    ./vanacli wallet export_private_key --wallet.name default --wallet.hotkey default

    # Konfirmasi backup
    read -p "Apakah Anda sudah membackup kunci privat? (y/n) " backup_confirmed
    if [ "$backup_confirmed" != "y" ]; then
        echo "Harap backup frasa mnemonik terlebih dahulu sebelum melanjutkan."
        exit 1
    fi
}

# Menghasilkan kunci enkripsi
function generate_encryption_keys() {
    echo "Menghasilkan kunci enkripsi..."
    cd $DLP_PATH
    ./keygen.sh
}

# Menulis kunci publik ke file .env
function write_public_key_to_env() {
    PUBLIC_KEY_FILE="$DLP_PATH/public_key_base64.asc"
    ENV_FILE="$DLP_PATH/.env"

    # Periksa apakah file kunci publik ada
    if [ ! -f "$PUBLIC_KEY_FILE" ]; then
        echo "File kunci publik tidak ditemukan: $PUBLIC_KEY_FILE"
        exit 1
    fi

    # Membaca isi kunci publik
    PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

    # Menulis kunci publik ke file .env
    echo "PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64=\"$PUBLIC_KEY\"" >> "$ENV_FILE"

    echo "Kunci publik berhasil ditulis ke file .env."
}

# Deploy kontrak pintar DLP
function deploy_smart_contracts() {
    echo "Mengkloning repositori kontrak pintar DLP..."
    cd $HOME
    rm -rf vana-dlp-smart-contracts
    git clone https://github.com/Josephtran102/vana-dlp-smart-contracts
    cd vana-dlp-smart-contracts

    echo "Menginstal Yarn..."
    npm install -g yarn
    echo "Verifikasi versi Yarn..."
    yarn --version

    echo "Menginstal dependensi kontrak pintar..."
    yarn install

    echo "Menyalin dan mengedit file .env..."
    cp .env.example .env
    nano .env  # Edit manual file .env dan isi informasi kontrak

    echo "Mendeploy kontrak pintar ke Moksha Testnet..."
    npx hardhat deploy --network moksha --tags DLPDeploy
}

# Mendaftarkan validator
function register_validator() {
    cd $HOME
    cd vana-dlp-chatgpt
    echo "Mendaftarkan validator..."
    ./vanacli dlp register_validator --stake_amount 10

    # Mendapatkan alamat Hotkey
    read -p "Masukkan alamat dompet Hotkey Anda: " HOTKEY_ADDRESS

    echo "Menyetujui validator..."
    ./vanacli dlp approve_validator --validator_address="$HOTKEY_ADDRESS"
}

# Membuat file .env
function create_env_file() {
    echo "Membuat file .env..."
    read -p "Masukkan alamat kontrak DLP: " DLP_CONTRACT
    read -p "Masukkan alamat kontrak Token DLP: " DLP_TOKEN_CONTRACT
    read -p "Masukkan OpenAI API Key: " OPENAI_API_KEY

    cat <<EOF > $DLP_PATH/.env
# Jaringan yang digunakan, saat ini Vana Moksha testnet
OD_CHAIN_NETWORK=moksha
OD_CHAIN_NETWORK_ENDPOINT=https://rpc.moksha.vana.org

# Opsional: OpenAI API key untuk pemeriksaan kualitas data tambahan
OPENAI_API_KEY="$OPENAI_API_KEY"

# Opsional: Alamat kontrak pintar DLP Anda setelah dideploy ke jaringan, berguna untuk pengujian lokal
DLP_MOKSHA_CONTRACT="$DLP_CONTRACT"

# Opsional: Alamat kontrak token DLP Anda setelah dideploy ke jaringan, berguna untuk pengujian lokal
DLP_TOKEN_MOKSHA_CONTRACT="$DLP_TOKEN_CONTRACT"
EOF
}

# Membuat file konfigurasi PM2
function create_pm2_config() {
    echo "Membuat file konfigurasi PM2..."
    cat <<EOF > $DLP_PATH/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'vana-validator',
      script: '$HOME/.local/bin/poetry',
      args: 'run python -m chatgpt.nodes.validator',
      cwd: '$DLP_PATH',
      interpreter: 'none', // Menentukan "none" untuk menghindari PM2 menggunakan interpreter Node.js default
      env: {
        PATH: '/root/.local/bin:/usr/local/bin:/usr/bin:/bin:/root/vana-dlp-chatgpt/myenv/bin',
        PYTHONPATH: '/root/vana-dlp-chatgpt',
        OD_CHAIN_NETWORK: 'moksha',
        OD_CHAIN_NETWORK_ENDPOINT: 'https://rpc.moksha.vana.org',
        OPENAI_API_KEY: '$OPENAI_API_KEY',
        DLP_MOKSHA_CONTRACT: '$DLP_CONTRACT',
        DLP_TOKEN_MOKSHA_CONTRACT: '$DLP_TOKEN_CONTRACT',
        PRIVATE_FILE_EN
