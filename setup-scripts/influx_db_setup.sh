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

printf "%b\n" "${BLUE}🚀 Starting InfluxDB Setup...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    printf "%b\n" "${RED}❌ Docker is not running. Please start Docker and try again.${NC}" >&2
    exit 1
fi

# Check if InfluxDB container already exists and remove it
if docker ps -a --format '{{.Names}}' | grep -q '^influxdb$'; then
    print_section "Removing Existing Container"
    printf "%b\n" "${BLUE}🔄 Removing existing InfluxDB container...${NC}"
    docker stop influxdb > /dev/null 2>&1
    docker rm influxdb > /dev/null 2>&1
fi

print_section "Starting InfluxDB Container"
printf "%b\n" "${BLUE}🐳 Starting InfluxDB 1.8 container...${NC}"

docker run -d -p 8086:8086 \
  -e INFLUXDB_DB=defaultdb \
  -e INFLUXDB_ADMIN_ENABLED=true \
  -e INFLUXDB_ADMIN_USER=admin \
  -e INFLUXDB_ADMIN_PASSWORD=adminpass \
  -e INFLUXDB_USER=user \
  -e INFLUXDB_USER_PASSWORD=userpass \
  --name=influxdb \
  -v influxdb:/var/lib/influxdb \
  --network="host" \
  influxdb:1.8

# Check if container started successfully
if [ $? -eq 0 ]; then
    printf "\n%b\n" "${GREEN}✅ InfluxDB is now running!${NC}"
    print_section "Connection Details"
    printf "   - Web Interface: ${GREEN}http://localhost:8086${NC}\n"
    printf "   - Admin Username: ${GREEN}admin${NC}\n"
    printf "   - Admin Password: ${GREEN}adminpass${NC}\n"
    printf "   - Regular User: ${GREEN}user${NC}\n"
    printf "   - User Password: ${GREEN}userpass${NC}\n"
    printf "   - Default Database: ${GREEN}defaultdb${NC}\n"
else
    printf "\n%b\n" "${RED}❌ Failed to start InfluxDB container.${NC}" >&2
    exit 1
fi

print_section "Setting Up Python Environment"
printf "%b\n" "${BLUE}🐍 Setting up Python environment...${NC}"

# Verify virtual environment
print_section "Verifying virtual environment"
if [ -n "$VIRTUAL_ENV" ] && [ -f "$VIRTUAL_ENV/bin/activate" ]; then
    printf "%b\n" "${GREEN}✅ Using virtual environment at $VIRTUAL_ENV${NC}"
else
    printf "%b\n" "${RED}❌ Virtual environment not activated${NC}" >&2
    printf "%b\n" "${YELLOW}Please run setup-scripts/env_setup.sh first${NC}" >&2
    exit 1
fi

# Install Python package
print_section "Installing Dependencies"
printf "%b\n" "${BLUE}📦 Installing Python dependencies...${NC}"
if pip3 install influxdb; then
    printf "\n%b\n" "${GREEN}✅ Successfully installed influxdb-python package${NC}"
else
    printf "\n%b\n" "${YELLOW}⚠️  Failed to install influxdb-python package. You may need to install it manually.${NC}" >&2
fi

# Print final instructions
printf "\n%b\n" "${GREEN}🎉 Setup completed!${NC}"
