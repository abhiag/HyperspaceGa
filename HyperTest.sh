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

# Configuration
PRIVATE_KEY_FILE="$HOME/my.pem"
AIOS_CLI_PATH="$HOME/.aios/aios-cli"
LOG_FILE="$HOME/hyperspace.log"

# Function to log messages
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$message" | tee -a "$LOG_FILE"
}

# Function to install a package using the system package manager
install_package() {
    local package=$1
    if command -v apt-get &> /dev/null; then
        log "📦 Installing $package using apt-get..."
        sudo apt-get install -y "$package"
    elif command -v yum &> /dev/null; then
        log "📦 Installing $package using yum..."
        sudo yum install -y "$package"
    elif command -v dnf &> /dev/null; then
        log "📦 Installing $package using dnf..."
        sudo dnf install -y "$package"
    elif command -v pacman &> /dev/null; then
        log "📦 Installing $package using pacman..."
        sudo pacman -S --noconfirm "$package"
    elif command -v zypper &> /dev/null; then
        log "📦 Installing $package using zypper..."
        sudo zypper install -y "$package"
    else
        log "❌ Unsupported package manager. Please install $package manually."
        exit 1
    fi
}

# Function to check for required tools and libraries
check_dependencies() {
    local dependencies=("curl" "bash" "htop" "nvtop" "wget")
    local libraries=("libssl.so.3")

    log "🔍 Checking dependencies and libraries..."

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "❌ Dependency '$dep' is not installed. Installing..."
            install_package "$dep"
        fi
    done

    for lib in "${libraries[@]}"; do
        if ! ldconfig -p | grep -q "$lib"; then
            log "❌ Library '$lib' is not installed. Installing..."
            if [[ "$lib" == "libssl.so.3" ]]; then
                install_package "libssl3"
            else
                log "❌ Unsupported library '$lib'. Please install it manually."
                exit 1
            fi
        fi
    done

    log "✅ All dependencies and libraries are installed."
}

# Function to set up CUDA environment variables
setup_cuda_env() {
    log "Setting up CUDA environment..."

    if [ ! -d "/usr/local/cuda-12.8/bin" ] || [ ! -d "/usr/local/cuda-12.8/lib64" ]; then
        log "⚠️ Warning: CUDA directories do not exist. CUDA might not be installed!"
    fi

    {
        echo 'export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}'
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}'
    } | sudo tee /etc/profile.d/cuda.sh >/dev/null

    source /etc/profile.d/cuda.sh
}

# Function to check if a port is in use
is_port_in_use() {
    local port=$1
    if lsof -i :"$port" > /dev/null 2>&1; then
        return 0 # Port is in use
    else
        return 1 # Port is not in use
    fi
}

# Function to install HyperSpace CLI and perform setup
install_hyperspace_cli() {
    log "🚀 Installing HyperSpace CLI..."
    if curl -s https://download.hyper.space/api/install | bash; then
        log "✅ HyperSpace CLI installed successfully!"
    else
        log "❌ Failed to install HyperSpace CLI. Please check your internet connection and try again."
        exit 1
    fi

    # Step 2: Add the aios-cli path to .bashrc
    log "🔄 Adding aios-cli path to .bashrc..."
    echo 'export PATH=$PATH:~/.aios' >> ~/.bashrc
    log "✅ aios-cli path added to .bashrc."

    # Step 3: Reload .bashrc to apply environment changes
    log "🔄 Reloading .bashrc..."
    source ~/.bashrc
    log "✅ .bashrc reloaded."

    # Step 4: Check if port 50051 is in use
    if is_port_in_use 50051; then
        log "❌ Port 50051 is already in use. Please free the port and try again."
        exit 1
    else
        log "✅ Port 50051 is available."
    fi

    # Step 5: Start Hyperspace node
    log "🚀 Starting the Hyperspace node..."
    "$AIOS_CLI_PATH" start &
    local node_pid=$!
    log "✅ Hyperspace node started with PID $node_pid."

    # Wait for the node to initialize
    log "⏳ Waiting for the Hyperspace node to initialize..."
    local timeout=60
    local elapsed=0
    while ! is_port_in_use 50051; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ "$elapsed" -ge "$timeout" ]; then
            log "❌ Timeout: Hyperspace node failed to initialize within $timeout seconds."
            kill "$node_pid" > /dev/null 2>&1
            exit 1
        fi
    done
    log "✅ Hyperspace node initialized successfully."

    # Step 7: Check the node status
    log "🔍 Checking node status..."
    "$AIOS_CLI_PATH" status
    if [ $? -ne 0 ]; then
        log "❌ Failed to check node status. Please check the logs for more details."
        exit 1
    fi

# Step 8: Proceed with downloading the required model
log "🔄 Downloading the required model..."

# Define the model URL (replace with the actual URL if available)
MODEL_URL="https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"

# Download the model using wget with live progress
log "📥 Downloading model from $MODEL_URL..."
if wget --progress=bar:force:noscroll -O /root/phi-2.Q4_K_M.gguf "$MODEL_URL"; then
    log "✅ Model downloaded successfully!"
else
    log "❌ Model download failed."
    exit 1
fi

    # Step 10: Import the private key
    log "🔑 Enter your private key:"
    read -p "Private Key: " private_key
    echo "$private_key" > "$PRIVATE_KEY_FILE"
    log "✅ Private key saved to $PRIVATE_KEY_FILE."

    # Step 11: Import the private key into Hive
    log "🔑 Importing private key into Hive..."
    "$AIOS_CLI_PATH" hive import-keys "$PRIVATE_KEY_FILE"
    if [ $? -ne 0 ]; then
        log "❌ Failed to import private key into Hive. Please check the logs for more details."
        exit 1
    fi

    # Step 12: Log in to Hive
    log "🔐 Logging into Hive..."
    "$AIOS_CLI_PATH" hive login
    if [ $? -ne 0 ]; then
        log "❌ Failed to log in to Hive. Please check the logs for more details."
        exit 1
    fi

    # Step 13: Connect to Hive
    log "🌐 Connecting to Hive..."
    "$AIOS_CLI_PATH" hive connect
    if [ $? -ne 0 ]; then
        log "❌ Failed to connect to Hive. Please check the logs for more details."
        exit 1
    fi

    # Step 14: Set Hive Tier
    log "🏆 Setting your Hive tier to 3..."
    "$AIOS_CLI_PATH" hive select-tier 3
    if [ $? -ne 0 ]; then
        log "❌ Failed to set Hive tier. Please check the logs for more details."
        exit 1
    fi

    log "🎉 HyperSpace installation and setup completed successfully!"
}

# Function to start the HyperSpace node
start_hyperspace_node() {
    log "🚀 Starting the HyperSpace node..."
    if "$AIOS_CLI_PATH" start; then
        log "✅ HyperSpace node started successfully!"
    else
        log "❌ Failed to start HyperSpace node. Please check the logs for more details."
        exit 1
    fi
}

# Function to stop the HyperSpace node
stop_hyperspace_node() {
    log "🛑 Stopping the HyperSpace node..."
    if "$AIOS_CLI_PATH" kill; then
        log "✅ HyperSpace node stopped successfully!"
    else
        log "❌ Failed to stop HyperSpace node. Please check the logs for more details."
        exit 1
    fi
}

# Function to check the status of the HyperSpace node
check_hyperspace_status() {
    log "🔍 Checking HyperSpace node status..."
    if "$AIOS_CLI_PATH" status; then
        log "✅ HyperSpace node status checked successfully!"
    else
        log "❌ Failed to check HyperSpace node status. Please check the logs for more details."
        exit 1
    fi
}

# Function to restart the HyperSpace node
restart_hyperspace_node() {
    log "🔄 Restarting the HyperSpace node..."
    stop_hyperspace_node
    start_hyperspace_node
    log "✅ HyperSpace node restarted."
}

# Function to uninstall HyperSpace
uninstall_hyperspace() {
    log "🧹 Uninstalling HyperSpace..."
    stop_hyperspace_node
    if rm -rf "$HOME/.aios" "$PRIVATE_KEY_FILE"; then
        log "✅ HyperSpace uninstalled successfully!"
    else
        log "❌ Failed to uninstall HyperSpace. Please check the logs for more details."
        exit 1
    fi
}

# Function to check Hyper Points
check_hyper_points() {
    log "🔍 Checking your Hyper Points..."
    "$AIOS_CLI_PATH" hive points
    if [ $? -ne 0 ]; then
        log "❌ Failed to check Hyper Points. Please check the logs for more details."
        exit 1
    fi
}

# Function to display the menu
show_menu() {
    echo -e "\n===== HyperSpace Node Manager ====="
    echo "1. Install HyperSpace"
    echo "2. Restart HyperSpace Node"
    echo "3. Stop HyperSpace Node"
    echo "4. Check HyperSpace Node Status"
    echo "5. Uninstall HyperSpace"
    echo "6. Check Hyper Points"
    echo "7. Exit"
    echo -e "===============================\n"
}


# Main script execution
while true; do
    show_menu
    read -p "Choose an option (1-6): " choice

    case $choice in
        1)
            check_dependencies
            setup_cuda_env
            install_hyperspace_cli
            ;;
        2)
            restart_hyperspace_node
            ;;
        3)
            stop_hyperspace_node
            ;;
        4)
            check_hyperspace_status
            ;;
        5)
            uninstall_hyperspace
            ;;
        6)
            check_hyper_points
            ;;
        7)
            log "👋 Exiting..."
            exit 0
            ;;
        *)
            log "❌ Invalid choice. Please select a valid option."
            ;;
    esac

    read -p "Press Enter to continue..."
done
