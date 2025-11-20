#!/bin/sh

#!/bin/sh

# Load environment configuration
ENV_CONFIG="$(cd "$(dirname "$0")" && pwd)/siotd_env.conf"
if [ ! -f "$ENV_CONFIG" ]; then
    printf "%b\n" "${RED}❌ Error: Environment configuration not found at $ENV_CONFIG${NC}" >&2
    printf "%b\n" "${YELLOW}Please run setup-scripts/env_setup.sh first${NC}" >&2
    exit 1
fi

# Source the configuration file to set variables
. "$ENV_CONFIG"

# Set colors for output (used in print functions)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set virtual environment path
VIRTUAL_ENV="$VENV_DIR"

# Add virtual environment's bin to PATH
if [ -n "$VIRTUAL_ENV" ] && [ -d "$VIRTUAL_ENV/bin" ]; then
    export PATH="$VIRTUAL_ENV/bin:$PATH"
fi

# Function to print section header
print_section() {
    section_title="$1"
    section_length=$(( ${#section_title} + 8 ))
    separator=$(printf '─%.0s' $(seq 1 $section_length))
    printf "\n%b\n" "${BLUE}┌${separator}┐"
    printf "%b\n" "│   🚀 ${section_title}  │"
    printf "%b\n" "└${separator}┘${NC}"
}

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        printf "%b\n" "${GREEN}✅ $1${NC}"
    else
        printf "%b\n" "${YELLOW}⚠️  $2${NC}" >&2
        return 1
    fi
}

printf "%b\n" "${BLUE}🚀 Starting MQTT Broker Setup...${NC}"

# Create config directory if it doesn't exist
mkdir -p "$MOSQUITTO_DIR" "$MOSQUITTO_DATA" "$MOSQUITTO_LOG"

# Check if the configuration file already exists
if [ -f "$CONFIG_FILE" ]; then
    printf "%b\n" "${YELLOW}⚠️  Warning: $CONFIG_FILE already exists.${NC}"
    read -p "   Do you want to overwrite it? (y/n) " -n 1 -r
    printf "\n"
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        printf "%b\n" "${YELLOW}❌ Operation cancelled.${NC}" >&2
        exit 1
    fi
fi

print_section "Creating MQTT configuration"

# Create the configuration file with the specified settings
cat > "$MOSQUITTO_CONFIG" << 'EOL'
# MQTT Configuration
persistence true
persistence_location /mosquitto/data
log_dest file /mosquitto/log/mosquitto.log
listener 1883
allow_anonymous true
user root
EOL

# Set appropriate permissions
chmod 644 "$MOSQUITTO_CONFIG"

printf "%b\n" "${GREEN}✅ Configuration file created: $MOSQUITTO_CONFIG${NC}"

print_section "Starting Mosquitto MQTT Broker"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    printf "%b\n" "${RED}❌ Docker is not running. Please start Docker and try again.${NC}" >&2
    exit 1
fi

# Check if mosquitto container is already running
if docker ps -a --format '{{.Names}}' | grep -q '^mosquitto$'; then
    printf "%b\n" "${YELLOW}⚠️  Mosquitto container already exists. Removing existing container...${NC}"
    docker stop mosquitto > /dev/null
    docker rm mosquitto > /dev/null
fi

# Start mosquitto container
printf "%b\n" "${BLUE}🚀 Starting Mosquitto container...${NC}"
docker run -it -d \
    -p 1883:1883 \
    -p 9001:9001 \
    --name=mosquitto \
    -v "$MOSQUITTO_CONFIG":/mosquitto/config/mosquitto.conf \
    -v "$MOSQUITTO_DATA":/mosquitto/data \
    -v "$MOSQUITTO_LOG":/mosquitto/log \
    --network="host" \
    eclipse-mosquitto

# Check if container started successfully
if [ $? -eq 0 ]; then
    printf "%b\n" "${GREEN}✅ Mosquitto MQTT Broker is now running!${NC}"
    print_section "MQTT Broker Details"
    printf "   - MQTT Port: 1883\n"
    printf "   - WebSocket Port: 9001\n"
    printf "   - Logs: ./mosquitto/log/mosquitto.log\n"
else
    printf "%b\n" "${RED}❌ Failed to start Mosquitto container.${NC}" >&2
    exit 1
fi

# Verify virtual environment
print_section "Verifying virtual environment"
if [ -n "$VIRTUAL_ENV" ] && [ -f "$VIRTUAL_ENV/bin/activate" ]; then
    printf "%b\n" "${GREEN}✅ Using virtual environment at $VIRTUAL_ENV${NC}"
    
    # Install Python package
    print_section "Installing Python Dependencies"
    printf "%b\n" "${BLUE}📦 Installing required Python packages...${NC}"
    if pip install paho-mqtt; then
        printf "%b\n" "${GREEN}✅ Successfully installed paho-mqtt${NC}"
    else
        printf "%b\n" "${YELLOW}⚠️  Failed to install paho-mqtt. You may need to install it manually: pip install paho-mqtt${NC}" >&2
    fi
else
    printf "%b\n" "${RED}❌ Virtual environment not activated${NC}" >&2
    printf "%b\n" "${YELLOW}Please run setup-scripts/env_setup.sh first${NC}" >&2
    exit 1
fi

printf "\n%b\n" "${GREEN}🎉 Setup completed successfully!${NC}"
