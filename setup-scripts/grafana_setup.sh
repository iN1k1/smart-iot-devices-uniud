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

printf "%b\n" "${BLUE}🚀 Starting Grafana Setup...${NC}"


print_section "Checking Docker Installation"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    printf "%b\n" "${RED}❌ Docker is not running. Please start Docker and try again.${NC}" >&2
    exit 1
fi
print_status "Docker is running" "Failed to connect to Docker"

print_section "Setting up Grafana Container"

# Check if Grafana container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^grafana$'; then
    printf "%b\n" "${YELLOW}⚠️  Grafana container already exists. Removing existing container...${NC}"
    docker stop grafana > /dev/null
    docker rm grafana > /dev/null
    print_status "Removed existing Grafana container" "Failed to remove existing container"
fi

# Start Grafana container
docker run -d \
  --name=grafana \
  -p 3000:3000 \
  --network="host" \
  grafana/grafana
#  -e "GF_SERVER_ROOT_URL=http://your_server_ip:3000" \

if [ $? -eq 0 ]; then
    printf "%b\n" "${GREEN}✅ Grafana container started successfully!${NC}"
    printf "%b\n" "   - Access Grafana at http://$(hostname -I | awk '{print $1}'):3000"
    printf "%b\n" "   - Or use the machine's hostname: http://$(hostname):3000"
    printf "%b\n" "   - Default username: admin"
    printf "%b\n" "   - Default password: admin"
else
    printf "%b\n" "${RED}❌ Failed to start Grafana container${NC}" >&2
    exit 1
fi

printf "%b\n" "${GREEN}✨ Grafana setup completed successfully!${NC}"
