#!/bin/bash

# Path untuk instalasi DLP Validator
DLP_PATH="$HOME/vana-dlp-chatgpt"

# Memeriksa apakah skrip dijalankan sebagai user root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Cobalah gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
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

    echo "Memverifikasi versi Python..."
    python3.11 --version

    echo "Menginstal Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bash_profile
    source $HOME/.bash_profile

    echo "Memverifikasi instalasi Poetry..."
    poetry --version
}

# Menginstal Node.js dan npm
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

# Menginstal PM2
function install_pm2() {
    echo "Memeriksa apakah PM2 sudah terinstal..."
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 sudah terinstal, versi: $(pm2 -v)"
    else
        echo "PM2 belum terinstal, menginstal sekarang..."
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
    echo "Ikuti langkah-langkah manual berikut:"
    echo "1. URL RPC: https://rpc.moksha.vana.org"
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
    if [ "$backup_confirmed" != "y" ];then
        echo "Harap backup mnemonic Anda terlebih dahulu, kemudian lanjutkan skrip."
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

    # Memeriksa apakah file kunci publik ada
    if [ ! -f "$PUBLIC_KEY_FILE" ];then
        echo "File kunci publik tidak ditemukan: $PUBLIC_KEY_FILE"
        exit 1
    fi

    # Membaca isi kunci publik
    PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

    # Menulis kunci publik ke file .env
    echo "PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64=\"$PUBLIC_KEY\"" >> "$ENV_FILE"

    echo "Kunci publik berhasil ditulis ke file .env."
}

# Mendeploy smart contract DLP
function deploy_smart_contracts() {
    echo "Mengkloning repositori smart contract DLP..."
    cd $HOME
    rm -rf vana-dlp-smart-contracts
    git clone https://github.com/Josephtran102/vana-dlp-smart-contracts
    cd vana-dlp-smart-contracts

    echo "Menginstal Yarn..."
    npm install -g yarn
    echo "Memverifikasi versi Yarn..."
    yarn --version

    echo "Menginstal dependensi smart contract..."
    yarn install

    echo "Menyalin dan mengedit file .env..."
    cp .env.example .env
    nano .env  # Edit file .env secara manual, isi informasi terkait smart contract

    echo "Mendeploy smart contract ke jaringan Moksha Testnet..."
    npx hardhat deploy --network moksha --tags DLPDeploy
}

# Mendaftarkan Validator
function register_validator() {
    cd $HOME
    cd vana-dlp-chatgpt
    echo "Mendaftarkan Validator..."
    ./vanacli dlp register_validator --stake_amount 10

    # Mendapatkan alamat Hotkey
    read -p "Masukkan alamat dompet Hotkey Anda: " HOTKEY_ADDRESS

    echo "Menyetujui Validator..."
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

# Opsional: Kunci API OpenAI untuk pemeriksaan kualitas data tambahan
OPENAI_API_KEY="$OPENAI_API_KEY"

# Opsional: Alamat kontrak pintar DLP Anda sendiri setelah dideploy ke jaringan, berguna untuk pengujian lokal
DLP_MOKSHA_CONTRACT="$DLP_CONTRACT"

# Opsional: Alamat kontrak token DLP Anda sendiri setelah dideploy ke jaringan, berguna untuk pengujian lokal
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
      interpreter: 'none', // Tentukan "none" untuk menghindari PM2 menggunakan interpreter Node.js default
      env: {
        PATH: '/root/.local/bin:/usr/local/bin:/usr/bin:/bin:/root/vana-dlp-chatgpt/myenv/bin',
        PYTHONPATH: '/root/vana-dlp-chatgpt',
        OD_CHAIN_NETWORK: 'moksha',
        OD_CHAIN_NETWORK_ENDPOINT: 'https://rpc.moksha.vana.org',
        OPENAI_API_KEY: '$OPENAI_API_KEY',
        DLP_MOKSHA_CONTRACT: '$DLP_CONTRACT',
        DLP_TOKEN_MOKSHA_CONTRACT: '$DLP_TOKEN_CONTRACT',
        PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64: '$PUBLIC_KEY'
      },
      restart_delay: 10000, // Penundaan restart dalam milidetik
      max_restarts: 10, // Jumlah restart maksimal
      autorestart: true,
      watch: false,
      // Tambahkan konfigurasi lainnya jika perlu
    },
  ],
};
EOF
}

# Memulai node Validator DLP menggunakan PM2
function start_validator() {
    echo "Memulai node Validator DLP menggunakan PM2..."
    pm2 start $DLP_PATH/ecosystem.config.js

    echo "Mengatur PM2 agar otomatis mulai saat boot..."
    pm2 startup systemd -u root --hp /root
    pm2 save

    echo "Node Validator DLP telah dimulai. Anda bisa melihat log dengan 'pm2 logs vana-validator'."
}

# Menginstal node Validator DLP
function install_dlp_node() {
    install_dependencies
    install_python_and_poetry
    install_nodejs_and_npm
    install_pm2
    clone_and_install_repos
    create_wallet
    export_private_keys
    generate_encryption_keys
    write_public_key_to_env 
    deploy_smart_contracts
    register_validator
    create_env_file
    create_pm2_config
    start_validator
}

# Melihat log node
function check_node() {
    pm2 logs vana-validator
}

# Menghapus node
function uninstall_node() {
    echo "Menghapus node Validator DLP..."
    pm2 delete vana-validator
    rm -rf $DLP_PATH
    echo "Node Validator DLP telah dihapus."
}

# Menu utama
function main_menu() {
    clear
    echo "========================= Instalasi Node Validator VANA DLP =======================================
    echo "Join Airdrop Node: https://t.me/airdrop_node"
    echo "Pilih operasi yang ingin Anda lakukan:"
    echo "1. Instalasi node Validator DLP"
    echo "2. Lihat log node"
    echo "3. Hapus node"
    read -p "Masukkan pilihan (1-3): " OPTION
    case $OPTION in
    1) install_dlp_node ;;
    2) check_node ;;
    3) uninstall_node ;;
    *) echo "Pilihan tidak valid." ;;
    esac
}

# Tampilkan menu utama
main_menu

