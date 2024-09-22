### VANA GUIDE DLP VALIDATOR
<img src="https://github.com/choir94/Vana/blob/main/Vanafounr.jpg?raw=true" alt="Vana Logo" width="400"/>

Sebelum menjalankan nodenya kerjakan dulu Task bot telegram
Vana Data Hero Mining:

https://t.me/VanaDataHeroBot/VanaDataHero?startapp=5649265696

Join Channel AirDrop Node Untuk diskusi

[AIRDROP NODE](https://t.me/airdrop_node)

## STEP BY STEP

## Install Dependencies (phyton 3.11)
```bash
sudo apt update
sudo apt install software-properties-common
```
```bash
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev
```
```bash
apt python3.11 --version
```
## Install Poetry
```bash
curl -sSL https://install.python-poetry.org | python3 -
```
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bash_profile
source $HOME/.bash_profile
poetry --version
```
## Install Node js dan Npm
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
```
```bash
echo 'export NVM_DIR="$HOME/.nvm"' >> $HOME/.bash_profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> $HOME/.bash_profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> $HOME/.bash_profile

source $HOME/.bash_profile 
```
```bash
nvm install --lts
```
```bash
node -v
npm -v
```
## Clone the repository
```bash
git clone https://github.com/vana-com/vana-dlp-chatgpt.git
cd vana-dlp-chatgpt
```
## Install Dependencies
```bash
poetry install
```
## Install Cli
```bash
apt install python3-pip
```
```bash
pip install vana
```
## Steps to Create a New Wallet

1. **Create the Wallet**
   ```bash
   vanacli wallet create --wallet.name default --wallet.hotkey default
   ```
   Simpan Phrase Hotkey wallet dan Coldkey wallet
2. **Export privatkey Cold wallet **
   ```bash
   vanacli wallet export_private_key
   ```
   Tekan Enter pilih Jenis wallet Coldkey Dan Buat kata sandi
   **Export privatkey Hot wallet**
   ```bash
   vanacli wallet export_private_key
   ```
   Tekan Enter,Pilih jenis wallet Hotkey Dan Buat kata sandi
   Simpan kedua wallet dan import wallet ke metamask

   Klaim Faucet isi kedua wallet
   [Faucet Vana](https://faucet.vana.org)

 ## Creating a DLP
   ```bash
    ./keygen.sh
   ```
   Masukkan Email dan enter
 ## Deploying a DLP Smart Contract
   ```bash
   cd $HOME
git clone https://github.com/vana-com/vana-dlp-smart-contracts.git
cd vana-dlp-smart-contracts
   ```
```bash
npm install -g yarn
yarn --version
```
```bash
yarn install
```
```bash
cp .env.example .env && nano .env
```
Edit Dan masukkan ke file env
```bash
DEPLOYER_PRIVATE_KEY=0x… (your Coldkey private key)
OWNER_ADDRESS=0x… (your Coldkey wallet address)
DLP_NAME=… (your chosen DLP name)
DLP_TOKEN_NAME=… (your chosen DLP token name)
DLP_TOKEN_SYMBOL=… (your chosen DLP token symbol)
```
Keluar dari file env CTRL + X Y

- Deploying a contract
```bash
npx hardhat deploy --network satori --tags DLPDeploy
```
Ini akan menghasilkan dua alamat: DataLiquidityPoolToken dan DataLiquidityPool. Simpan alamat ini dengan aman. Anda dapat memasukkannya ke dalam explorer untuk memverifikasi bahwa semuanya telah dilakukan dengan benar.
Buka tautan: 
[Explore scan](https://satori.vanascan.io)

## verify the contract
Ubah sesuai data anda
```bash
npx hardhat verify --network satori <YOUR_DataLiquidityPool_address>
```
```bash
npx hardhat verify --network satori <YOUR_DataLiquidityPoolToken_address> "<YOUR_DLP_TOKEN_NAME>" <YOUR_DLP_TOKEN_SYMBOL> <YOUR_COLDKEY_WALLET_ADDRESS>
```

Jika ada error skip dan lanjut

## Configure the DLP contract (DataLiquidityPool):
Visit 
https://satori.vanascan.io/address/YOUR_DLP_POOL_CONTRACT_ADDRESS

Go to "Write proxy" tab

Connect cold wallet yang telah di import tadi
Cari teks updateFileRewardDelay and set it to 0 klik konfirmasi di metamask

Kemudian cari addRewardsForContributors with 1000000000000000000000000 (1 million tokens) konfirmasi metamask
## Installing the validator
- Creating OpenAI API
Open link:

https://platform.openai.com/settings/profile?tab=api-keys
[Api OpenAi](https://platform.openai.com/settings/profile?tab=api-keys) 

Klik tombol “+Buat kunci rahasia baru”, masukkan nama, buat kunci API dan simpan

## extract the public key
```bash
cat /root/vana-dlp-chatgpt/public_key_base64.asc
```
Copy dan Simpan pubkey

Ke directory dlp
```bash
cd dan cd vana-dlp-chatgpt
```
Ubah File env
```bash
nano .env
```
Hapus semua isi file env Masukkan dan edit teks dibawah sesuai data anda
```bash
# Network to use, currently Vana Satori testnet  
OD_CHAIN_NETWORK=satori  
OD_CHAIN_NETWORK_ENDPOINT=https://rpc.satori.vana.org  
# Optional: OpenAI API key for additional data quality checks  
OPENAI_API_KEY="YOUR_API_KEY"  
# Optional: Your DLP smart contract address after deployment, useful for local testing  
DLP_SATORI_CONTRACT="YOUR_DataLiquidityPool"  
# Optional: Your DLP token contract address after deployment, useful for local testing  
DLP_TOKEN_SATORI_CONTRACT="YOUR_DataLiquidityPoolToken"  
# Private key for the DLP, refer to the "Generate validator encryption keys" section in the README  
PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64="YOUR_HUGE_OUTPUT or public key"
```
Impor DataLiquidityPoolToken Anda ke metamask ColdKey Wallet.
kirim minimal 10 token dlp anda ke alamat Hotkey wallet. 

## Register validator
```bash
./vanacli dlp register_validator --stake_amount 10
```
Tekan enter dua kali dan masukkan sandi yang dibuat sebelumnya. 
```bash
./vanacli dlp approve_validator --validator_address=<YOUR_HOTKEY_WALLET_ADDRESS>
```
Enter dan masukkan sandi
Jalankan Validator
```bash
sudo apt install tmux && tmux new-session -s VANA
```
```bash
poetry run python -m chatgpt.nodes.validator
```
Untuk Cek logs
```bash
sudo journalctl -u vana.service -f
```

## Done
Join Channel AirDrop Node Untuk diskusi

[AIRDROP NODE](https://t.me/airdrop_node)
