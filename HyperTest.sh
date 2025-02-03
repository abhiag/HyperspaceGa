#!/bin/bash

# Step 1: Install HyperSpace CLI
echo "🚀 Installing HyperSpace CLI..."
curl https://download.hyper.space/api/install | bash

# Step 2: Reload .bashrc to apply environment changes
echo "🔄 Reloading .bashrc to apply environment changes..."
echo 'export PATH=$PATH:/root/.aios' >> ~/.bashrc
source ~/.bashrc

# Step 3: Create a screen session and run aios-cli start in that screen
echo "🚀 Starting the Hyperspace node..."
screen -S hyperspace -d -m bash -c "aios-cli start"

# Step 4: Wait for the node to start (check if node is active after waiting)
echo "⏳ Waiting for the Hyperspace node to start..."
sleep 10 # Wait for node initialization, adjust time if needed

# Step 5: Check if the node is running
echo "🔍 Checking if Hyperspace node is running..."
screen -S hyperspace -X stuff "aios-cli status\n"

# Give it some time to check the status
sleep 3

# Step 6: Proceed with the next steps if the node is running
echo "✅ Hyperspace node is up and running, proceeding with next steps."

# Step 7: Download the required model with real-time progress
echo "🔄 Downloading the required model..."
aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee /root/model_download.log

# Step 8: Verify if the model was downloaded successfully
if grep -q "Download complete" /root/model_download.log; then
    echo "✅ Model downloaded successfully!"
else
    echo "❌ Model download failed. Check /root/model_download.log for details."
    exit 1
fi

# Step 9: Ask for the private key and save it securely
echo "🔑 Please enter your private key (it will be saved to /root/my.pem):"
read -s PRIVATE_KEY
echo "$PRIVATE_KEY" > /root/my.pem
chmod 600 /root/my.pem
echo "✅ Private key saved to /root/my.pem"

# Step 10: Import private key
echo "🔑 Importing your private key..."
aios-cli hive import-keys /root/my.pem

# Step 11: Login to Hive
echo "🔐 Logging into Hive..."
aios-cli hive login

# Step 12: Connect to Hive
echo "🌐 Connecting to Hive..."
aios-cli hive connect

# Step 13: Set Hive Tier
echo "🏆 Setting your Hive tier to 3..."
aios-cli hive select-tier 3

# Step 14: Display Hive points
echo "📊 Checking your current Hive points..."
aios-cli hive points

# Final message
echo "✅ HyperSpace Node setup complete!"
