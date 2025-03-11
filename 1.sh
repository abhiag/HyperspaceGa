#!/bin/bash

# Configuration
LOG_FILE="$HOME/hyperspace.log"
NODES=()  # Array to store active nodes (base_dir, port, pid)

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
    local base_dir=$1
    local port=$2
    local private_key_file="$base_dir/my.pem"
    local aios_cli_path="$base_dir/.aios/aios-cli"

    log "🚀 Installing HyperSpace CLI in $base_dir..."
    mkdir -p "$base_dir"
    cd "$base_dir" || exit 1

    log "🔍 Running installation script..."
    if curl -s https://download.hyper.space/api/install | bash; then
        log "✅ HyperSpace CLI installed successfully in $base_dir!"
    else
        log "❌ Failed to install HyperSpace CLI in $base_dir. Please check your internet connection and try again."
        exit 1
    fi

    # Move the binary from /root/.aios to the correct base_dir
    if [[ -f "/root/.aios/aios-cli" ]]; then
        log "🔄 Moving aios-cli binary to $base_dir/.aios..."
        mkdir -p "$base_dir/.aios"
        mv "/root/.aios/aios-cli" "$base_dir/.aios/"
        log "✅ aios-cli binary moved to $base_dir/.aios."
    else
        log "❌ aios-cli binary not found in /root/.aios. Installation failed."
        exit 1
    fi

    # Verify installation
    if [[ -f "$aios_cli_path" ]]; then
        log "✅ aios-cli binary found in $base_dir."
    else
        log "❌ aios-cli binary not found in $base_dir. Installation failed."
        exit 1
    fi

    # Step 2: Add the aios-cli path to .bashrc
    log "🔄 Adding aios-cli path to .bashrc..."
    echo "export PATH=\$PATH:$base_dir/.aios" >> ~/.bashrc
    log "✅ aios-cli path added to .bashrc."

    # Step 3: Reload .bashrc to apply environment changes
    log "🔄 Reloading .bashrc..."
    source ~/.bashrc
    log "✅ .bashrc reloaded."

    # Step 4: Check if the specified port is in use
    if is_port_in_use "$port"; then
        log "❌ Port $port is already in use. Please free the port and try again."
        exit 1
    else
        log "✅ Port $port is available."
    fi

    # Step 5: Start Hyperspace node on the specified port
    log "🚀 Starting the Hyperspace node on port $port..."
    "$aios_cli_path" start --port "$port" &
    local node_pid=$!
    log "✅ Hyperspace node started with PID $node_pid."

    # Add node to the NODES array
    NODES+=("$base_dir:$port:$node_pid")

    # Wait for the node to initialize
    log "⏳ Waiting for the Hyperspace node to initialize..."
    local timeout=60
    local elapsed=0
    while ! is_port_in_use "$port"; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ "$elapsed" -ge "$timeout" ]; then
            log "❌ Timeout: Hyperspace node failed to initialize within $timeout seconds."
            kill "$node_pid" > /dev/null 2>&1
            exit 1
        fi
    done
    log "✅ Hyperspace node initialized successfully on port $port."

    # Step 7: Check the node status
    log "🔍 Checking node status..."
    "$aios_cli_path" status
    if [ $? -ne 0 ]; then
        log "❌ Failed to check node status. Please check the logs for more details."
        exit 1
    fi

    # Step 8: Proceed with downloading the required model
    log "🔄 Downloading the required model..."
    MODEL_URL="https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
    log "📥 Downloading model from $MODEL_URL..."
    if wget --progress=bar:force:noscroll -O "$base_dir/phi-2.Q4_K_M.gguf" "$MODEL_URL"; then
        log "✅ Model downloaded successfully!"
    else
        log "❌ Model download failed."
        exit 1
    fi

    # Step 9: Prompt for private key
    log "🔑 Enter your private key for the node in $base_dir:"
    read -p "Private Key: " private_key
    echo "$private_key" > "$private_key_file"
    log "✅ Private key saved to $private_key_file."

    # Step 10: Import the private key into Hive
    log "🔑 Importing private key into Hive..."
    "$aios_cli_path" hive import-keys "$private_key_file"
    if [ $? -ne 0 ]; then
        log "❌ Failed to import private key into Hive. Please check the logs for more details."
        exit 1
    fi

    # Step 11: Log in to Hive
    log "🔐 Logging into Hive..."
    "$aios_cli_path" hive login
    if [ $? -ne 0 ]; then
        log "❌ Failed to log in to Hive. Please check the logs for more details."
        exit 1
    fi

    # Step 12: Connect to Hive
    log "🌐 Connecting to Hive..."
    "$aios_cli_path" hive connect
    if [ $? -ne 0 ]; then
        log "❌ Failed to connect to Hive. Please check the logs for more details."
        exit 1
    fi

    # Step 13: Set Hive Tier
    log "🏆 Setting your Hive tier to 3..."
    "$aios_cli_path" hive select-tier 3
    if [ $? -ne 0 ]; then
        log "❌ Failed to set Hive tier. Please check the logs for more details."
        exit 1
    fi

    log "🎉 HyperSpace installation and setup completed successfully in $base_dir!"
}

# Function to list installed nodes
list_installed_nodes() {
    if [ ${#NODES[@]} -eq 0 ]; then
        log "❌ No nodes are currently installed."
        return 1
    else
        log "📋 Installed Nodes:"
        for i in "${!NODES[@]}"; do
            local base_dir=$(echo "${NODES[$i]}" | cut -d: -f1)
            local port=$(echo "${NODES[$i]}" | cut -d: -f2)
            log "$((i+1)). $base_dir (Port: $port)"
        done
    fi
}

# Function to uninstall a HyperSpace node
uninstall_hyperspace() {
    log "🧹 Uninstalling HyperSpace node..."

    # List installed nodes
    list_installed_nodes || return 1

    # Prompt the user to select a node to uninstall
    read -p "Enter the number of the node you want to uninstall: " node_number
    if [[ ! "$node_number" =~ ^[0-9]+$ ]] || [ "$node_number" -lt 1 ] || [ "$node_number" -gt "${#NODES[@]}" ]; then
        log "❌ Invalid selection. Please enter a valid number."
        return 1
    fi

    # Get the selected node details
    local selected_node="${NODES[$((node_number-1))]}"
    local base_dir=$(echo "$selected_node" | cut -d: -f1)
    local port=$(echo "$selected_node" | cut -d: -f2)
    local pid=$(echo "$selected_node" | cut -d: -f3)

    # Stop the node if it's running
    log "🛑 Stopping the HyperSpace node on port $port..."
    if kill "$pid" > /dev/null 2>&1; then
        log "✅ HyperSpace node on port $port stopped successfully."
    else
        log "⚠️ Failed to stop the HyperSpace node on port $port. It may already be stopped."
    fi

    # Remove the node directory
    log "🧹 Removing node directory $base_dir..."
    if rm -rf "$base_dir"; then
        log "✅ Node directory $base_dir removed successfully."
    else
        log "❌ Failed to remove node directory $base_dir."
        return 1
    fi

    # Remove the node from the NODES array
    NODES=("${NODES[@]:0:$((node_number-1))}" "${NODES[@]:$node_number}")
    log "✅ Node uninstalled successfully."
}

# Function to display the menu
show_menu() {
    echo -e "\n===== HyperSpace Node Manager ====="
    echo "1. Install HyperSpace - How many nodes you want to install"
    echo "2. Restart HyperSpace Node"
    echo "3. Stop HyperSpace Node - Stop node according to active ports"
    echo "4. Check HyperSpace Node Status - Show the active ports"
    echo "5. Uninstall HyperSpace?"
    echo "6. Check Hyper Points - Which node points you want to check?"
    echo "7. Exit"
    echo -e "===============================\n"
}

# Main script execution
check_dependencies
setup_cuda_env

while true; do
    show_menu
    read -p "Choose an option (1-7): " choice

    case $choice in
        1)
            read -p "How many nodes do you want to install? " num_nodes
            for ((i=1; i<=num_nodes; i++)); do
                base_dir="$HOME/hyperspace_node_$i"
                port=$((50050 + i))
                install_hyperspace_cli "$base_dir" "$port"
            done
            ;;
        2)
            read -p "Enter the port of the node you want to restart: " port
            restart_hyperspace_node "$port"
            ;;
        3)
            read -p "Enter the port of the node you want to stop: " port
            stop_hyperspace_node "$port"
            ;;
        4)
            check_hyperspace_status
            ;;
        5)
            read -p "Enter the base directory of the node you want to uninstall: " base_dir
            uninstall_hyperspace "$base_dir"
            ;;
        6)
            read -p "Enter the base directory of the node you want to check points for: " base_dir
            check_hyper_points "$base_dir"
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
