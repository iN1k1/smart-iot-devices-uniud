#!/bin/bash

# Define the configuration file path
CONFIG_FILE="mosquitto.conf"

# Check if the configuration file already exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Warning: $CONFIG_FILE already exists in the current directory."
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Create the configuration file with the specified settings
cat > "$CONFIG_FILE" << 'EOL'
# MQTT Configuration
# Message persistence
persistence true
persistence_location /mosquitto/data
log_dest file /mosquitto/log/mosquitto.log
listener 1883
allow_anonymous true
user root
EOL

# Set appropriate permissions
chmod 644 "$CONFIG_FILE"

echo "Configuration file created: $(pwd)/$CONFIG_FILE"

# Execute mosquitto using docker
docker run -it -d -p 1883:1883 -p 9001:9001 --name=mosquitto -v ./mosquitto.conf:/mosquitto/config/mosquitto.conf eclipse-mosquitto 

# Install paho mqtt
pip install paho-mqtt
