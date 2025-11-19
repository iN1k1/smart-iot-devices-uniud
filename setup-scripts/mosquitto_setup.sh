#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting MQTT Broker Setup...${NC}"

# Define the configuration file path
CONFIG_FILE="mosquitto.conf"

# Check if the configuration file already exists
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  Warning: $CONFIG_FILE already exists in the current directory.${NC}"
    read -p "   Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Operation cancelled.${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}🔧 Creating MQTT configuration file...${NC}"

# Create the configuration file with the specified settings
cat > "$CONFIG_FILE" << 'EOL'
# MQTT Configuration
persistence true
persistence_location /mosquitto/data
log_dest file /mosquitto/log/mosquitto.log
listener 1883
allow_anonymous true
user root
EOL

# Set appropriate permissions
chmod 644 "$CONFIG_FILE"

echo -e "${GREEN}✅ Configuration file created: $(pwd)/$CONFIG_FILE${NC}"

echo -e "\n${BLUE}🐳 Starting Mosquitto MQTT Broker in Docker...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if mosquitto container is already running
if docker ps -a --format '{{.Names}}' | grep -q '^mosquitto$'; then
    echo -e "${YELLOW}⚠️  Mosquitto container already exists. Removing existing container...${NC}"
    docker stop mosquitto > /dev/null
    docker rm mosquitto > /dev/null
fi

# Create necessary directories if they don't exist
mkdir -p ./mosquitto/data ./mosquitto/log

# Start mosquitto container
echo -e "${BLUE}🚀 Starting Mosquitto container...${NC}"
docker run -it -d \
    -p 1883:1883 \
    -p 9001:9001 \
    --name=mosquitto \
    -v $(pwd)/mosquitto.conf:/mosquitto/config/mosquitto.conf \
    -v $(pwd)/mosquitto/data:/mosquitto/data \
    -v $(pwd)/mosquitto/log:/mosquitto/log \
    eclipse-mosquitto

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Mosquitto MQTT Broker is now running!${NC}"
    echo -e "\n${BLUE}📊 MQTT Broker Details:${NC}"
    echo -e "   - MQTT Port: 1883"
    echo -e "   - WebSocket Port: 9001"
    echo -e "   - Logs: ./mosquitto/log/mosquitto.log"
else
    echo -e "${YELLOW}❌ Failed to start Mosquitto container.${NC}"
    exit 1
fi

echo -e "\n${BLUE}📦 Installing required Python packages...${NC}"
pip install paho-mqtt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully installed paho-mqtt${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to install paho-mqtt. You may need to install it manually: pip install paho-mqtt${NC}"
fi

echo -e "\n${GREEN}🎉 Setup completed successfully!${NC}"
