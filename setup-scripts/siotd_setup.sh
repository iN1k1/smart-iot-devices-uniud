#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting SIoTD Project Environment Setup...${NC}"

# Define variables
PROJECT_DIR="$HOME/Desktop/SIoTD-Projects"
VENV_DIR="$PROJECT_DIR/siotdenv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section header
print_section() {
    echo -e "\n${BLUE}🔧 $1${NC}"
}

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${YELLOW}⚠️  $2${NC}"
        return 1
    fi
}

# Create project directory
print_section "Setting up project directory"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}ℹ️  Project directory already exists at $PROJECT_DIR${NC}"
else
    mkdir -p "$PROJECT_DIR"
    print_status "Created project directory at $PROJECT_DIR" "Failed to create project directory"
fi

# Navigate to project directory
cd "$PROJECT_DIR" || { echo -e "${RED}❌ Failed to navigate to $PROJECT_DIR${NC}"; exit 1; }

# Create virtual environment
print_section "Setting up Python virtual environment"
if [ -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}ℹ️  Virtual environment already exists at $VENV_DIR${NC}"
else
    echo -e "${BLUE}Creating Python virtual environment...${NC}"
    python3 -m venv "$VENV_DIR" --system-site-packages
    print_status "Created virtual environment at $VENV_DIR" "Failed to create virtual environment"
fi

# Activate virtual environment
print_section "Activating virtual environment"
source "$VENV_DIR/bin/activate"
print_status "Virtual environment activated" "Failed to activate virtual environment"

# Install required packages
print_section "Installing Python packages"
pip install --upgrade pip
pip install setuptools wheel
print_status "Updated pip and installed setuptools and wheel" "Failed to install Python packages"

# Install Adafruit Blinka
print_section "Installing Adafruit Blinka"
if command_exists raspi-blinka; then
    echo -e "${YELLOW}ℹ️  Adafruit Blinka is already installed${NC}"
else
    echo -e "${BLUE}Installing Adafruit Blinka...${NC}"
    pip install --upgrade adafruit-python-shell
    wget -q https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py
    
    if [ -f "raspi-blinka.py" ]; then
        echo -e "${BLUE}Running Adafruit Blinka installer...${NC}"
        echo -e "${YELLOW}⚠️  This may require sudo privileges and a system reboot${NC}"
        sudo -E env PATH="$PATH" python3 raspi-blinka.py
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Adafruit Blinka installed successfully!${NC}"
            echo -e "\n${YELLOW}⚠️  Please reboot your system and run this script again to complete the setup.${NC}"
            exit 0
        else
            echo -e "${YELLOW}⚠️  Adafruit Blinka installation may require a system reboot.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Failed to download Adafruit Blinka installer${NC}"
    fi
fi

# Install DHT sensor library
print_section "Installing DHT sensor library"
if python -c "import adafruit_dht" &> /dev/null; then
    echo -e "${YELLOW}ℹ️  DHT sensor library is already installed${NC}"
else
    echo -e "${BLUE}Installing DHT sensor library...${NC}"
    pip install adafruit-circuitpython-dht
    print_status "Installed DHT sensor library" "Failed to install DHT sensor library"
fi


# Final instructions
echo -e "\n${GREEN}🎉 Setup completed successfully!${NC}"
