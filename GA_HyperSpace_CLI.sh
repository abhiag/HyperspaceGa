#!/bin/bash

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

#!/bin/bash

echo "🔍 Checking for NVIDIA GPU..."
if command -v nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA GPU detected!"
    
    echo "🔍 Checking if CUDA is installed..."
    if [ -d "/usr/local/cuda" ]; then
        echo "✅ CUDA is already installed!"
    else
        echo "❌ CUDA not found. Installing CUDA Toolkit..."
        sudo apt update && sudo apt install -y cuda-toolkit
    fi

    # Add CUDA to PATH
    echo "🔄 Adding CUDA paths to environment variables..."
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    source ~/.bashrc
    echo "✅ CUDA setup completed!"
else
    echo "⚠️ NVIDIA GPU not found. Skipping CUDA setup."
fi

echo "🚀 Installing HyperSpace CLI..."

while true; do
    curl -s https://download.hyper.space/api/install | bash | tee /root/hyperspace_install.log

    if ! grep -q "Failed to parse version from release data." /root/hyperspace_install.log; then
        echo "✅ HyperSpace CLI installed successfully!"
        break
    else
        echo "❌ Installation failed. Retrying in 10 seconds..."
        sleep 5
    fi
done

# Step 2: Add aios-cli to PATH and persist it
echo "🔄 Adding ~/.aios/aios-cli path to .bashrc..."
echo 'export PATH=$PATH:~/.aios' >> ~/.bashrc
export PATH=$PATH:~/.aios
source ~/.bashrc

# Step 3: Start the Hyperspace node in a screen session
echo "🚀 Starting the Hyperspace node in the background..."
screen -S hyperspace -d -m bash -c "~/.aios/aios-cli start"

# Step 4: Check if aios-cli is available
echo "🔍 Checking if ~/.aios/aios-cli is installed..."
if ! command -v ~/.aios/aios-cli &> /dev/null; then
    echo "❌ aios-cli not found. Reinstalling..."
    curl -s https://download.hyper.space/api/install | bash
    if ! command -v ~/.aios/aios-cli &> /dev/null; then
        echo "❌ aios-cli still not found. Exiting."
        exit 1
    fi
fi

# Step 5: Check node status
echo "🔍 Checking node status..."
~/.aios/aios-cli status

# Step 6: Download the required model
echo "🔄 Downloading the required model..."
while true; do
    ~/.aios/aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee /root/model_download.log

    if grep -q "Download complete" /root/model_download.log; then
        echo "✅ Model downloaded successfully!"
        break
    else
        echo "❌ Model download failed. Retrying in 10 seconds..."
        sleep 5
    fi
done

# Step 7: Check for existing private key
if [ -f "/root/my.pem" ]; then
    echo "🔑 Existing private key found. Using it..."
else
    echo "🔑 No private key found. Enter your private key:"
    read -s -p "Private Key: " private_key
    echo "$private_key" > /root/my.pem
    chmod 600 /root/my.pem
    echo "✅ Hyperspace key saved to /root/my.pem"
fi

# Step 8: Import private key
echo "🔑 Importing your Hyperspace key..."
~/.aios/aios-cli hive import-keys /root/my.pem

# Step 9: Login to Hive
echo "🔐 Logging into Hive..."
~/.aios/aios-cli hive login

# Step 10: Connect to Hive
echo "🌐 Connecting to Hive..."
~/.aios/aios-cli hive connect

# Step 11: Display system info
echo "🖥️ Fetching system information..."
~/.aios/aios-cli system-info

# Step 12: Set Hive Tier
echo "🏆 Setting your Hive tier to 5..."
~/.aios/aios-cli hive select-tier 5 

# Step 13: Check Hive points in a loop every 10 seconds
echo "📊 Checking your Hive points every 10 seconds..."
echo "✅ HyperSpace Node setup complete!"
echo "ℹ️ Use 'CTRL + A + D' to detach the screen and 'screen -r gaspace' to reattach."

while true; do
    echo "ℹ️ Press 'CTRL + A + D' to detach the screen, 'screen -r gaspace' to reattach."
    ~/.aios/aios-cli hive points
    sleep 10
done

done
