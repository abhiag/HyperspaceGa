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
        CUDA_PATH="/usr/local/cuda"

        if [ -d "$CUDA_PATH" ]; then
            echo "✅ CUDA directory found at $CUDA_PATH. Adding to PATH..."

            # Add to bashrc if not already present
            if ! grep -q "/usr/local/cuda/bin" ~/.bashrc; then
                echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
                echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
            fi

            # Export immediately for the script
            export PATH=/usr/local/cuda/bin:$PATH
            export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

            # Reload bashrc
            source ~/.bashrc
            exec bash  # Reload shell environment

            # Debug: Print current paths
            echo "🔍 Checking if CUDA is in PATH after update..."
            echo "PATH = $PATH"
            echo "LD_LIBRARY_PATH = $LD_LIBRARY_PATH"

            # Final check if nvcc works
            if command -v nvcc &>/dev/null; then
                echo "✅ CUDA path successfully added!"
            else
                echo "❌ CUDA path not detected in PATH. Try manually running 'source ~/.bashrc' and rechecking."
            fi
        else
            echo "❌ CUDA directory not found at $CUDA_PATH. Skipping CUDA path setup."
        fi
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
    screen -S gaspace -dm bash -c 'curl -O https://raw.githubusercontent.com/abhiag/HyperspaceGa/main/GA_HyperSpace_CLI.sh && chmod +x GA_HyperSpace_CLI.sh && ./GA_HyperSpace_CLI.sh; echo "✅ Screen execution complete" > ~/screen_debug.log'
    sleep 2  # Allow time for screen to start

    # Step 6: Verify screen was created
    if screen -list | grep -q "gaspace"; then
        echo "✅ Screen session 'gaspace' created successfully!"
    else
        echo "❌ Failed to create screen session. Checking logs..."
        cat ~/screen_debug.log
        exit 1
    fi

    # Step 7: Attach to the screen session
    screen -r gaspace

    # If execution reaches here, it means the script failed, ask user if they want to retry
    read -p "❌ Something went wrong. Do you want to retry? (y/n): " retry
    if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        echo "Exiting setup."
        exit 1
    fi
done
