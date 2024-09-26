#!/bin/bash

# Lokasi penyimpanan skrip
SCRIPT_PATH="$HOME/vana.sh"

# Fungsi untuk menginstal Git
function install_git() {
    if ! git --version &> /dev/null; then
        echo "Git belum terinstal. Menginstal Git..."
        sudo apt update && sudo apt install -y git
    else
        echo "Git sudah terinstal: $(git --version)"
    fi
}

# Fungsi untuk menginstal Python
function install_python() {
    if ! python3 --version &> /dev/null; then
        echo "Python belum terinstal. Menginstal Python..."
        sudo apt update && sudo apt install -y python3 python3-pip
    fi
}

# Fungsi untuk menginstal Node.js dan npm
function install_node() {
    if ! node --version &> /dev/null; then
        echo "Node.js belum terinstal. Menginstal Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    if ! npm --version &> /dev/null; then
        echo "npm belum terinstal. Menginstal npm..."
        sudo apt install -y npm
    fi
}

# Fungsi untuk menginstal nvm
function install_nvm() {
    if ! command -v nvm &> /dev/null; then
        echo "nvm belum terinstal. Menginstal nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
}

# Fungsi untuk menggunakan Node.js versi 18
function use_node_18() {
    nvm install 18
    nvm use 18
}

# Fungsi untuk mengkloning repository Git dan masuk ke direktori
function clone_and_enter_repo() {
    echo "Mengkloning repository vana-dlp-chatgpt..."
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git
    cd vana-dlp-chatgpt || { echo "Tidak bisa masuk ke direktori, skrip dihentikan"; exit 1; }
}

# Fungsi untuk menginstal dependensi proyek
function install_dependencies() {
    cp .env.example .env
    echo "Menginstal vana menggunakan pip..."
    apt install python3-pip
    pip3 install vana || { echo "Gagal menginstal dependensi, skrip dihentikan"; exit 1; }
}

# Fungsi untuk menjalankan pembuatan kunci
function run_keygen() {
    echo "Membuat dompet default..."
    vanacli wallet create --wallet.name default --wallet.hotkey default

    echo "Menjalankan pembuatan kunci..."
    ./keygen.sh
    echo "Masukkan nama Anda, email, dan durasi kunci."
}

# Fungsi untuk menerapkan kontrak pintar DLP
function deploy_dlp_contract() {
    cd .. || { echo "Tidak bisa kembali ke direktori sebelumnya, skrip dihentikan"; exit 1; }
    echo "Mengkloning repository kontrak pintar DLP..."
    git clone https://github.com/vana-com/vana-dlp-smart-contracts.git
    cd vana-dlp-smart-contracts || { echo "Tidak bisa masuk ke direktori, skrip dihentikan"; exit 1; }

    echo "Menginstal dependensi..."
    sudo apt install -y cmdtest
    npm install --global yarn

    # Meminta input dari pengguna dan mengimpor ke file .env
    read -p "Masukkan private key cold wallet Anda (DEPLOYER_PRIVATE_KEY=0x...): " deployer_private_key
    read -p "Masukkan alamat cold wallet Anda (OWNER_ADDRESS=0x...): " owner_address
    read -p "Masukkan nama DLP (DLP_NAME=...): " dlp_name
    read -p "Masukkan nama token DLP (DLP_TOKEN_NAME=...): " dlp_token_name
    read -p "Masukkan simbol token DLP (DLP_TOKEN_SYMBOL=...): " dlp_token_symbol

    # Impor ke file .env
    echo "DEPLOYER_PRIVATE_KEY=${deployer_private_key}" >> .env
    echo "OWNER_ADDRESS=${owner_address}" >> .env
    echo "DLP_NAME=${dlp_name}" >> .env
    echo "DLP_TOKEN_NAME=${dlp_token_name}" >> .env
    echo "DLP_TOKEN_SYMBOL=${dlp_token_symbol}" >> .env

    echo "Informasi telah disimpan di file .env."
}

# Fungsi untuk menginisialisasi npm dan menginstal Hardhat
function setup_hardhat() {
    npm init -y
    npm install --save-dev hardhat
    nvm install 18
    nvm use 18
    npm install --save-dev hardhat
    npx hardhat

    # Meminta private key dari pengguna
    read -p "Masukkan private key cold wallet Anda untuk konfigurasi accounts: [\"0xprivatekey\"]: " cold_key

    # Memperbarui file hardhat.config.js
    echo "module.exports = {
        solidity: \"^0.8.0\",
        networks: {
            hardhat: {
                accounts: [\"$cold_key\"]
            }
        }
    };" > hardhat.config.js

    echo "Konfigurasi Hardhat selesai."
}

# Fungsi untuk menerapkan kontrak dan menyimpan alamatnya
function deploy_and_save_addresses() {
    echo "Menerapkan kontrak..."
    npx hardhat deploy --network satori --tags DLPDeploy

    echo "Simpan alamat DataLiquidityPool dan DataLiquidityPoolToken."
    echo "Tekan tombol apa saja untuk kembali ke menu utama..."
    read -n 1 -s
}

# Fungsi untuk memulai node validator
function start_validator_node() {
    cd ~/vana-dlp-chatgpt || { echo "Tidak bisa masuk ke direktori, skrip dihentikan"; exit 1; }

    read -rp "Masukkan alamat DataLiquidityPool (DLP_SATORI_CONTRACT=0x...): " dlp_satori_contract
    read -rp "Masukkan alamat DataLiquidityPoolToken (DLP_TOKEN_SATORI_CONTRACT=0x...): " dlp_token_satori_contract
    read -rp "Masukkan kunci publik dompet (PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64): " public_key

    # Impor ke file .env
    echo "DLP_SATORI_CONTRACT=${dlp_satori_contract}" >> .env
    echo "DLP_TOKEN_SATORI_CONTRACT=${dlp_token_satori_contract}" >> .env
    echo "PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64=${public_key}" >> .env

    echo "Menginstal Poetry..."
    sudo apt install -y python3-poetry

    echo "Mendaftarkan node validator..."
    ./vanacli dlp register_validator --stake_amount 10

    echo "Memulai node validator..."
    poetry run python -m chatgpt.nodes.validator

    echo "Konfigurasi node validator selesai."
    echo "Tekan tombol apa saja untuk kembali ke menu utama..."
    read -n 1 -s
}

# Fungsi untuk menerapkan lingkungan
function deploy_environment() {
    install_git
    install_python
    install_node
    install_nvm
    use_node_18
    clone_and_enter_repo
    install_dependencies
    run_keygen
    deploy_dlp_contract
    setup_hardhat
    deploy_and_save_addresses
}

# Fungsi untuk menu utama
function main_menu() {
    while true; do
        clear
       
        echo "Join airdrop node: https://t.me/airdrop_node"
        
        echo "Untuk keluar dari skrip, tekan ctrl+c di keyboard."
        echo "Pilih operasi yang ingin dijalankan:"
        echo "1) Menerapkan lingkungan"
        echo "2) Memulai node validator"
        echo "0) Keluar"
        echo "================================================================"
        read -rp "Masukkan pilihan Anda: " choice

        case $choice in
            1)
                deploy_environment
                ;;
            2)
                start_validator_node
                ;;
            0)
                echo "Keluar dari skrip"
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi"
                ;;
        esac
    done
}

# Memulai menu utama
main_menu
