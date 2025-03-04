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

# Configuration
PRIVATE_KEY_FILE="$HOME/my.pem"
AIOS_CLI_PATH="$HOME/.aios/aios-cli"
SCREEN_SESSION="hyperspace"

# Function to log messages
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check for required tools and libraries
check_dependencies() {
    local dependencies=("curl" "bash" "screen")
    local libraries=("libssl.so.3")

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "❌ Dependency '$dep' is not installed. Please install it and try again."
            exit 1
        fi
    done

    for lib in "${libraries[@]}"; do
        if ! ldconfig -p | grep -q "$lib"; then
            log "❌ Library '$lib' is not installed. Please install it and try again."
            exit 1
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

# Function to install HyperSpace CLI
install_hyperspace_cli() {
    log "🚀 Installing HyperSpace CLI..."
    curl -s https://download.hyper.space/api/install | bash
    log "✅ HyperSpace CLI installed successfully!"
}

# Function to start the HyperSpace node
start_hyperspace_node() {
    log "🚀 Starting the HyperSpace node in the background..."
    "$AIOS_CLI_PATH" start
}

# Function to stop the HyperSpace node
stop_hyperspace_node() {
    log "🛑 Stopping the HyperSpace node..."
    "$AIOS_CLI_PATH" kill
}

# Function to check the status of the HyperSpace node
check_hyperspace_status() {
    log "🔍 Checking HyperSpace node status..."
    "$AIOS_CLI_PATH" status
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
    rm -rf "$HOME/.aios" "$PRIVATE_KEY_FILE"
    log "✅ HyperSpace uninstalled."
}

# Function to display the menu
show_menu() {
    echo -e "\n===== HyperSpace Node Manager ====="
    echo "1. Install HyperSpace"
    echo "2. Restart HyperSpace Node"
    echo "3. Stop HyperSpace Node"
    echo "4. Check HyperSpace Node Status"
    echo "5. Uninstall HyperSpace"
    echo "6. Exit"
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
            log "👋 Exiting..."
            exit 0
            ;;
        *)
            log "❌ Invalid choice. Please select a valid option."
            ;;
    esac

    read -p "Press Enter to continue..."
done
