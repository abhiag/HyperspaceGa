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
LOG_DIR="/var/log/hyperspace"
INSTALL_LOG="$LOG_DIR/hyperspace_install.log"
MODEL_DOWNLOAD_LOG="$LOG_DIR/model_download.log"
PRIVATE_KEY_FILE="$HOME/my.pem"
AIOS_CLI_PATH="$HOME/.aios/aios-cli"
SCREEN_SESSION="hyperspace"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check for required tools
check_dependencies() {
    local dependencies=("curl" "bash" "screen")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "❌ Dependency '$dep' is not installed. Please install it and try again."
            exit 1
        fi
    done
    log "✅ All dependencies are installed."
}

# Function to install HyperSpace CLI
install_hyperspace_cli() {
    log "🚀 Installing HyperSpace CLI..."
    local retry_count=0
    local max_retries=5
    local retry_delay=5

    while [[ $retry_count -lt $max_retries ]]; do
        curl -s https://download.hyper.space/api/install | bash >> "$INSTALL_LOG" 2>&1

        if ! grep -q "Failed to parse version from release data." "$INSTALL_LOG"; then
            log "✅ HyperSpace CLI installed successfully!"
            return 0
        else
            retry_count=$((retry_count + 1))
            log "❌ Installation failed. Retrying in $retry_delay seconds... (Attempt $retry_count/$max_retries)"
            sleep $retry_delay
            retry_delay=$((retry_delay * 2)) # Exponential backoff
        fi
    done

    log "❌ Failed to install HyperSpace CLI after $max_retries attempts. Check $INSTALL_LOG for details."
    exit 1
}

# Function to start the HyperSpace node
start_hyperspace_node() {
    log "🚀 Starting the HyperSpace node in the background..."
    local start_script="$HOME/start_hyperspace.sh"
    echo "$AIOS_CLI_PATH start" > "$start_script"
    chmod +x "$start_script"
    screen -S "$SCREEN_SESSION" -d -m "$start_script"
    log "✅ HyperSpace node started in a screen session."
}

# Function to stop the HyperSpace node
stop_hyperspace_node() {
    log "🛑 Stopping the HyperSpace node..."
    if "$AIOS_CLI_PATH" kill; then
        log "✅ HyperSpace node stopped using 'aios-cli kill'."
    else
        log "❌ Failed to stop HyperSpace node using 'aios-cli kill'. Attempting to stop via screen..."
        if screen -list | grep -q "$SCREEN_SESSION"; then
            screen -XS "$SCREEN_SESSION" quit
            log "✅ HyperSpace node stopped via screen."
        else
            log "❌ No active HyperSpace node found."
        fi
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
    rm -rf "$HOME/.aios" "$PRIVATE_KEY_FILE" "$LOG_DIR"
    log "✅ HyperSpace uninstalled."
}

# Function to display the menu
show_menu() {
    echo -e "\n===== HyperSpace Node Manager ====="
    echo "1. Install HyperSpace"
    echo "2. Restart HyperSpace Node"
    echo "3. Stop HyperSpace Node"
    echo "4. Uninstall HyperSpace"
    echo "5. Exit"
    echo -e "===============================\n"
}

# Main script execution
while true; do
    show_menu
    read -p "Choose an option (1-5): " choice

    case $choice in
        1)
            check_dependencies
            install_hyperspace_cli
            ;;
        2)
            restart_hyperspace_node
            ;;
        3)
            stop_hyperspace_node
            ;;
        4)
            uninstall_hyperspace
            ;;
        5)
            log "👋 Exiting..."
            exit 0
            ;;
        *)
            log "❌ Invalid choice. Please select a valid option."
            ;;
    esac

    read -p "Press Enter to continue..."
done
