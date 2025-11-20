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

printf "%b\n" "${BLUE}🚀 Starting SIoTD Adafruit (DHT) Setup...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# Verify virtual environment
print_section "Verifying virtual environment"
if [ -z "$VIRTUAL_ENV" ] || [ ! -d "$VIRTUAL_ENV" ]; then
    printf "%b\n" "${RED}❌ Virtual environment not found at $VENV_DIR${NC}" >&2
    printf "%b\n" "${YELLOW}Please run setup-scripts/env_setup.sh first${NC}" >&2
    exit 1
fi

# Verify virtual environment
print_section "Verifying virtual environment"
if [ -n "$VIRTUAL_ENV" ] && [ -f "$VIRTUAL_ENV/bin/activate" ]; then
    printf "%b\n" "${GREEN}✅ Using virtual environment at $VIRTUAL_ENV${NC}"
else
    printf "%b\n" "${RED}❌ Virtual environment not activated${NC}" >&2
    printf "%b\n" "${YELLOW}Please run setup-scripts/env_setup.sh first${NC}" >&2
    exit 1
fi
# Install Adafruit Blinka
print_section "Installing Adafruit Blinka"
if python3 -c "import board" 2>/dev/null; then
    printf "%b\n" "${YELLOW}ℹ️  Adafruit Blinka is already installed${NC}"
else

    printf "%b\n" "${BLUE}Installing Adafruit Blinka...${NC}"
    pip install --upgrade adafruit-python-shell
    wget -q https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py
    
    if [ -f "raspi-blinka.py" ]; then
        printf "%b\n" "${BLUE}Running Adafruit Blinka installer...${NC}"
        printf "%b\n" "${YELLOW}⚠️  This may require sudo privileges and a system reboot${NC}"
        sudo -E env PATH="$PATH" python3 raspi-blinka.py
        
        if [ $? -eq 0 ]; then
            printf "%b\n" "${GREEN}✅ Adafruit Blinka installed successfully!${NC}"
            printf "\n%b\n" "${YELLOW}⚠️  Please reboot your system and run this script again to complete the setup.${NC}"
            exit 0
        else
            printf "%b\n" "${YELLOW}⚠️  Adafruit Blinka installation may require a system reboot.${NC}" >&2
        fi
    else
        printf "%b\n" "${YELLOW}⚠️  Failed to download Adafruit Blinka installer${NC}" >&2
    fi
fi

# Install DHT sensor library
print_section "Installing DHT sensor library"
if python -c "import adafruit_dht" 2>/dev/null; then
    printf "%b\n" "${YELLOW}ℹ️  DHT sensor library is already installed${NC}"
else
    printf "%b\n" "${BLUE}Installing DHT sensor library...${NC}"
    if pip install adafruit-circuitpython-dht; then
        # Verify the installation by importing the module
        if python3 -c "import adafruit_dht" 2>/dev/null; then
            printf "%b\n" "${GREEN}✅ DHT sensor library installed and verified${NC}"
        else
            printf "%b\n" "${YELLOW}⚠️  DHT sensor library installed but verification failed${NC}" >&2
            printf "%b\n" "${YELLOW}   Try running the script again or check the installation manually.${NC}" >&2
        fi
    else
        printf "%b\n" "${RED}❌ Failed to install DHT sensor library${NC}" >&2
        exit 1
    fi
fi

# Final instructions
printf "\n%b\n" "${GREEN}🎉 Adafruit setup completed successfully!${NC}"
