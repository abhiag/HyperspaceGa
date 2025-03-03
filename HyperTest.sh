#!/bin/bash

# Infinite loop to retry on failure
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
    printf "${RESET}\n"

    echo "🚀 Starting HyperSpace Node Setup..."

    # Step 1: Check for NVIDIA GPU
    if command -v nvidia-smi &>/dev/null; then
        echo "✅ NVIDIA GPU detected!"
        
        # Step 2: Check if CUDA is installed
        if command -v nvcc &>/dev/null; then
            echo "✅ CUDA is already installed."
        else
            echo "⚠️ CUDA not found. Installing now..."
            sudo apt-get update && sudo apt-get install -y cuda-toolkit
        fi

        # Step 3: Add CUDA to PATH
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
    else
        echo "❌ No NVIDIA GPU found. Skipping CUDA installation."
    fi

    # Step 4: Check if screen session "gaspace" exists
    if screen -list | grep -q "gaspace"; then
        echo "🟡 Screen session 'gaspace' already exists."
        read -p "Do you want to switch to it? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            screen -r gaspace
            exit 0
        else
            echo "❌ Exiting without switching."
            exit 1
        fi
    fi

    # Step 5: Create a new screen session and run the HyperSpace script
    echo "🚀 Creating a new 'gaspace' screen session..."
    screen -S gaspace -dm bash -c 'curl -O https://raw.githubusercontent.com/abhiag/HyperspaceGa/main/GA_HyperSpace_CLI.sh && chmod +x GA_HyperSpace_CLI.sh && ./GA_HyperSpace_CLI.sh'

    # Step 6: Wait until the session is listed, then switch
    while ! screen -list | grep -q "gaspace"; do sleep 1; done

    # Step 7: Attach to the screen session
    screen -r gaspace

    # If execution reaches here, it means the script failed, ask user if they want to retry
    read -p "❌ Something went wrong. Do you want to retry? (y/n): " retry
    if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        echo "Exiting setup."
        exit 1
    fi
done
