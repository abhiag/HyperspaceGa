#!/bin/bash

# Infinite loop to keep retrying the script if any part fails
while true; do
    printf "\n"
    cat <<EOF

░██████╗░░█████╗░  ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
██╔════╝░██╔══██╗  ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
██║░░██╗░███████║  ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
██║░░╚██╗██╔══██║  ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
╚██████╔╝██║░░██║  ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
░╚═════╝░╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░
EOF

    printf "\n\n"

    # GA CRYPTO Banner
    GREEN="\033[0;32m"
    RESET="\033[0m"
    printf "${GREEN}"
    printf "🚀 THIS SCRIPT IS PROUDLY CREATED BY **GA CRYPTO**! 🚀\n"
    printf "Stay connected for updates:\n"
    printf "   • Telegram: https://t.me/GaCryptOfficial\n"
    printf "   • X (formerly Twitter): https://x.com/GACryptoO\n"
    printf "${RESET}"

  # Step 1: Install HyperSpace CLI
echo "🚀 Installing HyperSpace CLI..."

while true; do
    curl -s https://download.hyper.space/api/install | bash >> /root/hyperspace_install.log 2>&1
    
    if ! tail -n 1000 /root/hyperspace_install.log | grep -q "Failed to parse version from release data."; then
        echo "✅ HyperSpace CLI installed successfully!"
        break
    else
        echo "❌ Installation failed. Retrying in 10 seconds..."
        sleep 5
    fi
done

# Step 2: Add aios-cli to PATH and persist it
echo "🔄 Adding aios-cli path to .bashrc..."
echo 'export PATH=$PATH:$HOME/.aios' >> ~/.bashrc
export PATH=$PATH:$HOME/.aios
source ~/.bashrc

# Step 3: Start the Hyperspace node in a screen session
echo "🚀 Starting the Hyperspace node in the background..."
echo "$HOME/.aios/aios-cli start" > /root/start_hyperspace.sh
chmod +x /root/start_hyperspace.sh
screen -S hyperspace -d -m /root/start_hyperspace.sh

# Step 4: Wait for node startup
echo "⏳ Waiting for the Hyperspace node to start..."
sleep 10

# Step 5: Check if aios-cli is available
echo "🔍 Checking if aios-cli is installed..."
if ! command -v aios-cli &> /dev/null; then
    echo "❌ aios-cli not found. Exiting."
    exit 1
fi

# Step 6: Check node status
echo "🔍 Checking node status..."
aios-cli status

# Step 7: Download the required model
echo "🔄 Downloading the required model..."

while true; do
    aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee /root/model_download.log
    
    if tail -n 1000 /root/model_download.log | grep -q "Download complete"; then
        echo "✅ Model downloaded successfully!"
        break
    else
        echo "❌ Model download failed. Retrying in 10 seconds..."
        sleep 5
    fi
done

# Step 8: Ask for private key securely
echo "🔑 Enter your private key:"
read -s -p "Private Key: " private_key
echo $private_key > /root/my.pem
chmod 600 /root/my.pem
echo "✅ Private key saved to /root/my.pem"

# Step 9: Import private key
echo "🔑 Importing your private key..."
aios-cli hive import-keys /root/my.pem

# Step 10: Login to Hive
echo "🔐 Logging into Hive..."
aios-cli hive login

# Step 11: Connect to Hive
echo "🌐 Connecting to Hive..."
aios-cli hive connect

# Step 12: Display system info
echo "🖥️ Fetching system information..."
aios-cli system-info

# Step 13: Set Hive Tier
echo "🏆 Setting your Hive tier to 3..."
aios-cli hive select-tier 5 

# Step 14: Check Hive points in a loop every 10 seconds
echo "📊 Checking your Hive points every 10 seconds..."
echo "✅ HyperSpace Node setup complete!"
echo "ℹ️ Use 'CTRL + A + D' to detach the screen and 'screen -r hyperspace' to reattach."

while true; do
    echo "ℹ️ Press 'CTRL + A + D' to detach the screen, 'screen -r hyperspace' to reattach."
    aios-cli hive points
    sleep 10
done
