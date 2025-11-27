#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section header
print_section() {
    local section_title="$1"
    local section_length=$(( ${#section_title} + 8 ))
    local separator=$(printf '─%.0s' $(seq 1 $section_length))
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        printf "%b\n" "${RED}❌ Docker is not running. Please start Docker and try again.${NC}" >&2
        exit 1
    fi
}

# Function to check virtual environment
check_virtualenv() {
    if [ -z "$VIRTUAL_ENV" ] || [ ! -d "$VIRTUAL_ENV" ]; then
        printf "%b\n" "${RED}❌ Virtual environment not found at $VENV_DIR${NC}" >&2
        printf "%b\n" "${YELLOW}Please run this script with the --env-setup flag first${NC}" >&2
        exit 1
    fi
}

# Main setup function
main() {
    local setup_env=false
    local setup_mosquitto=false
    local setup_influxdb=false
    local setup_grafana=false
    local setup_adafruit=false
    local setup_telegram=false
    local setup_aiagents=false
    local setup_all=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --env-setup) setup_env=true ;;
            --mosquitto) setup_mosquitto=true ;;
            --influxdb) setup_influxdb=true ;;
            --grafana) setup_grafana=true ;;
            --adafruit) setup_adafruit=true ;;
            --telegram) setup_telegram=true ;;
            --ai) setup_aiagents=true ;;
            --all) setup_all=true ;;
            -h|--help) show_usage; exit 0 ;;
            *) echo "Unknown option: $1"; show_usage; exit 1 ;;
        esac
        shift
    done

    # If no specific option is provided, run all configurations
    if [ "$setup_env" = false ] && [ "$setup_mosquitto" = false ] && \
       [ "$setup_influxdb" = false ] && [ "$setup_grafana" = false ] && \
       [ "$setup_adafruit" = false ] && [ "$setup_telegram" = false ] && \
       [ "$setup_aiagents" = false ] && [ "$setup_all" = false ]; then
        printf "%b\n" "${BLUE}No specific options provided. Running all configurations...${NC}"
        setup_all=true
    fi

    # Set all flags if --all is specified
    if [ "$setup_all" = true ]; then
        setup_env=true
        setup_mosquitto=true
        setup_influxdb=true
        setup_grafana=true
        setup_adafruit=true
        setup_telegram=true
        setup_aiagents=true
    fi

    # Environment setup
    if [ "$setup_env" = true ]; then
        setup_environment
    fi

    # Mosquitto setup
    if [ "$setup_mosquitto" = true ]; then
        setup_mosquitto
    fi

    # InfluxDB setup
    if [ "$setup_influxdb" = true ]; then
        setup_influxdb
    fi

    # Grafana setup
    if [ "$setup_grafana" = true ]; then
        setup_grafana
    fi

    # Adafruit setup
    if [ "$setup_adafruit" = true ]; then
        setup_adafruit
    fi

    # Telegram bot setup
    if [ "$setup_telegram" = true ]; then
        setup_telegram_bot
    fi

    # AI gents setup
    if [ "$setup_aiagents" = true ]; then
        setup_aiagents
    fi

    printf "\n%b\n" "${GREEN}✨ All requested setups completed successfully!${NC}"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --env-setup    Set up the project environment
  --mosquitto    Set up Mosquitto MQTT broker
  --influxdb     Set up InfluxDB
  --grafana      Set up Grafana
  --adafruit     Set up Adafruit dependencies
  --telegram     Set up Telegram bot
  --ai           Set up AI Agents/configuration
  --all          Run all setup steps
  -h, --help     Show this help message

Example:
  $0 --env-setup --mosquitto --influxdb
  $0 --all

EOF
}

# Environment setup
setup_environment() {
    print_section "Setting Up Project Environment"
    
    # Define variables
    PROJECT_DIR="$HOME/Desktop/SIoTD-Projects"
    VENV_DIR="$HOME/siotdenv"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    ROOT_DIR="$(dirname "$SCRIPT_DIR")"
    CONFIG_FILE="$ROOT_DIR/siotd.conf"

    # Create project directory and subdirectories
    for dir in "$PROJECT_DIR" \
               "$PROJECT_DIR/weather" \
               "$PROJECT_DIR/assistant" \
               "$PROJECT_DIR/basics" \
               "$PROJECT_DIR/ai" \
               "$PROJECT_DIR/chatbot"; do
        if [ -d "$dir" ]; then
            printf "%b\n" "${GREEN}✅ Directory already exists: $dir${NC}"
        else
            if mkdir -p "$dir"; then
                print_status "Created directory: $dir" "Failed to create directory: $dir"
            fi
        fi
    done

    # Create environment configuration file in the project directory
    CONFIG_FILE="$PROJECT_DIR/siotd.conf"
    cat > "$CONFIG_FILE" << EOL
# SIoTD Environment Configuration
# This file is automatically generated by setup.sh
# Do not edit this file manually as it will be overwritten

# Project Directories
export PROJECT_DIR="$PROJECT_DIR"
export VENV_DIR="$VENV_DIR"

# Application Directories
export MOSQUITTO_DIR="\$PROJECT_DIR/mosquitto"
export MOSQUITTO_CONFIG="\$MOSQUITTO_DIR/mosquitto.conf"
export MOSQUITTO_DATA="\$MOSQUITTO_DIR/data"
export MOSQUITTO_LOG="\$MOSQUITTO_DIR/log"

# InfluxDB Configuration
export INFLUXDB_DIR="\$PROJECT_DIR/influxdb"

# Python Virtual Environment
export VIRTUAL_ENV="$VENV_DIR"

# Colors for output
export GREEN='\\033[0;32m'
export YELLOW='\\033[1;33m'
export BLUE='\\033[0;34m'
export RED='\\033[0;31m'
export NC='\\033[0m' # No Color

# AI Configuration
export HUGGINGFACE_MODEL="Qwen/Qwen3-4B-Instruct-2507"
export HUGGINGFACE_TOKEN=""  # Add your HuggingFace token here
EOL

    # Make the configuration file readable by all
    chmod 644 "$CONFIG_FILE"
    print_status "Created environment configuration at $CONFIG_FILE" "Failed to create environment configuration"

    # Install required system packages
    print_section "Installing System Dependencies"
    if ! command_exists python3-venv; then
        printf "%b\n" "${BLUE}Installing python3-venv...${NC}"
        sudo apt-get update
        sudo apt-get install -y python3-venv
        print_status "Installed python3-venv" "Failed to install python3-venv"
    else
        printf "%b\n" "${YELLOW}ℹ️  python3-venv is already installed${NC}"
    fi

    # Create virtual environment
    print_section "Setting Up Python Virtual Environment"
    if [ -d "$VENV_DIR" ]; then
        printf "%b\n" "${YELLOW}ℹ️  Virtual environment already exists at $VENV_DIR${NC}"
    else
        printf "%b\n" "${BLUE}Creating Python virtual environment...${NC}"
        python3 -m venv "$VENV_DIR" --system-site-packages
        print_status "Created virtual environment at $VENV_DIR" "Failed to create virtual environment"
    fi

    # Activate virtual environment
    if [ -f "$VENV_DIR/bin/activate" ]; then
        printf "%b\n" "${BLUE}Activating virtual environment...${NC}"
        . "$VENV_DIR/bin/activate"
        
        if [ -n "$VIRTUAL_ENV" ]; then
            printf "%b\n" "${GREEN}✅ Virtual environment activated${NC}"
            
            # Add activation to .bashrc if not already present
            if ! grep -q "source $VENV_DIR/bin/activate" ~/.bashrc 2>/dev/null; then
                printf "%b\n" "${BLUE}Adding virtual environment activation to ~/.bashrc...${NC}"
                echo "# Activate virtual environment for smart-iot-devices-uniud" >> ~/.bashrc
                echo "if [ -f $VENV_DIR/bin/activate ]; then" >> ~/.bashrc
                echo "    source $VENV_DIR/bin/activate" >> ~/.bashrc
                echo "fi" >> ~/.bashrc
                print_status "Added virtual environment activation to ~/.bashrc" "Failed to update ~/.bashrc"
            else
                printf "%b\n" "${YELLOW}ℹ️  Virtual environment activation already in ~/.bashrc${NC}"
            fi
            
            # Install Python packages
            print_section "Installing Python Packages"
            pip install --upgrade pip
            pip install setuptools wheel
            print_status "Updated pip and installed setuptools and wheel" "Failed to install Python packages"
            
            # Install Docker if not installed
            if ! command_exists docker; then
                print_section "Installing Docker"
                printf "%b\n" "${BLUE}Installing Docker...${NC}"
                
                sudo curl -sSL https://get.docker.com | sudo sh
                
                # Add current user to docker group to avoid using sudo with docker commands
                sudo usermod -aG docker $USER
                
                # Start and enable Docker service
                sudo systemctl enable docker
                sudo systemctl start docker
                
                print_status "Docker installed successfully" "Failed to install Docker"
                printf "%b\n" "${YELLOW}ℹ️  You may need to log out and back in for the docker group changes to take effect.${NC}"
            else
                printf "%b\n" "${YELLOW}ℹ️  Docker is already installed${NC}"
                
                # Check if Docker service is running
                if ! systemctl is-active --quiet docker; then
                    printf "%b\n" "${BLUE}Starting Docker service...${NC}"
                    sudo systemctl start docker
                    print_status "Docker service started" "Failed to start Docker service"
                fi
            fi
        else
            printf "%b\n" "${RED}❌ Virtual environment activation failed${NC}"
            exit 1
        fi
    else
        printf "%b\n" "${RED}❌ Virtual environment activation script not found at $VENV_DIR/bin/activate${NC}"
        exit 1
    fi
}

# Mosquitto MQTT broker setup
setup_mosquitto() {
    print_section "Setting Up Mosquitto MQTT Broker"
    check_virtualenv
    check_docker
    
    # Load configuration
    . "$ROOT_DIR/siotd.conf" 2>/dev/null || {
        printf "%b\n" "${RED}❌ Error: Failed to load configuration from $ROOT_DIR/siotd.conf${NC}" >&2
        exit 1
    }
    
    # Create necessary directories if they don't exist
    if [ ! -d "$MOSQUITTO_DIR" ] || [ ! -d "$MOSQUITTO_DATA" ] || [ ! -d "$MOSQUITTO_LOG" ]; then
        mkdir -p "$MOSQUITTO_DIR" "$MOSQUITTO_DATA" "$MOSQUITTO_LOG"
        print_status "Created Mosquitto directories" "Failed to create Mosquitto directories"
    else
        printf "%b\n" "${GREEN}✅ Mosquitto directories already exist${NC}"
    fi
    
    # Create Mosquitto configuration if it doesn't exist
    if [ ! -f "$MOSQUITTO_CONFIG" ]; then
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
        print_status "Created Mosquitto configuration at $MOSQUITTO_CONFIG" "Failed to create Mosquitto configuration"
    else
        printf "%b\n" "${GREEN}✅ Mosquitto configuration already exists at $MOSQUITTO_CONFIG${NC}"
    fi
    
    # Check if Mosquitto container is already running
    if docker ps -a --format '{{.Names}}' | grep -q '^mosquitto$'; then
        printf "%b\n" "${YELLOW}⚠️  Mosquitto container already exists. Removing existing container...${NC}"
        docker stop mosquitto > /dev/null
        docker rm mosquitto > /dev/null
        print_status "Removed existing Mosquitto container" "Failed to remove existing container"
    fi
    
    # Start Mosquitto container
    printf "%b\n" "${BLUE}🚀 Starting Mosquitto container...${NC}"
    docker run -d \
        -p 1883:1883 \
        -p 9001:9001 \
        --name=mosquitto \
        -v "$MOSQUITTO_CONFIG:/mosquitto/config/mosquitto.conf" \
        -v "$MOSQUITTO_DATA:/mosquitto/data" \
        -v "$MOSQUITTO_LOG:/mosquitto/log" \
        --network="host" \
        eclipse-mosquitto
    
    if [ $? -eq 0 ]; then
        printf "%b\n" "${GREEN}✅ Mosquitto MQTT Broker is now running!${NC}"
        print_section "MQTT Broker Details"
        printf "   - MQTT Port: 1883\n"
        printf "   - WebSocket Port: 9001\n"
        printf "   - Logs: $MOSQUITTO_LOG/mosquitto.log\n"
    else
        printf "%b\n" "${RED}❌ Failed to start Mosquitto container.${NC}" >&2
        exit 1
    fi
    
    # Install Python MQTT client
    print_section "Installing Python Dependencies"
    printf "%b\n" "${BLUE}📦 Installing required Python packages...${NC}"
    if pip install paho-mqtt; then
        printf "%b\n" "${GREEN}✅ Successfully installed paho-mqtt${NC}"
    else
        printf "%b\n" "${YELLOW}⚠️  Failed to install paho-mqtt. You may need to install it manually: pip install paho-mqtt${NC}" >&2
    fi
}

# InfluxDB setup
setup_influxdb() {
    print_section "Setting Up InfluxDB"
    check_virtualenv
    check_docker
    
    # Check if InfluxDB container already exists and remove it
    if docker ps -a --format '{{.Names}}' | grep -q '^influxdb$'; then
        print_section "Removing Existing Container"
        printf "%b\n" "${BLUE}🔄 Removing existing InfluxDB container...${NC}"
        docker stop influxdb > /dev/null 2>&1
        docker rm influxdb > /dev/null 2>&1
        print_status "Removed existing InfluxDB container" "Failed to remove existing container"
    fi
    
    # Start InfluxDB container
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
    
    # Install Python client
    print_section "Installing Python Dependencies"
    printf "%b\n" "${BLUE}📦 Installing Python dependencies...${NC}"
    if pip install influxdb; then
        printf "\n%b\n" "${GREEN}✅ Successfully installed influxdb-python package${NC}"
    else
        printf "\n%b\n" "${YELLOW}⚠️  Failed to install influxdb-python package. You may need to install it manually.${NC}" >&2
    fi
}

# Grafana setup
setup_grafana() {
    print_section "Setting Up Grafana"
    check_docker
    
    # Check if Grafana container already exists
    if docker ps -a --format '{{.Names}}' | grep -q '^grafana$'; then
        printf "%b\n" "${YELLOW}⚠️  Grafana container already exists. Removing existing container...${NC}"
        docker stop grafana > /dev/null
        docker rm grafana > /dev/null
        print_status "Removed existing Grafana container" "Failed to remove existing container"
    fi
    
    # Start Grafana container
    printf "%b\n" "${BLUE}🚀 Starting Grafana container...${NC}"
    docker run -d \
      --name=grafana \
      -p 3000:3000 \
      --network="host" \
      grafana/grafana
    
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
}

# Adafruit setup
setup_adafruit() {
    print_section "Setting Up Adafruit Dependencies"
    check_virtualenv
    
    # Install Adafruit Blinka
    printf "%b\n" "${BLUE}Installing Adafruit Blinka...${NC}"
    if python3 -c "import board" 2>/dev/null; then
        printf "%b\n" "${YELLOW}ℹ️  Adafruit Blinka is already installed${NC}"
    else
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
    printf "%b\n" "${BLUE}Installing DHT sensor library...${NC}"
    if python -c "import adafruit_dht" 2>/dev/null; then
        printf "%b\n" "${YELLOW}ℹ️  DHT sensor library is already installed${NC}"
    else
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
}

# Telegram bot setup
setup_telegram_bot() {
    print_section "Setting Up Telegram Bot"
    check_virtualenv
    
    # Install required packages
    printf "%b\n" "${BLUE}📦 Installing Python dependencies...${NC}"
    if pip install python-telegram-bot python-dotenv; then
        print_status "Successfully installed Python packages" "Failed to install Python packages"
    else
        printf "%b\n" "${RED}❌ Failed to install Python packages${NC}" >&2
        exit 1
    fi
    
    # Ensure chatbot directory exists
    local chatbot_dir="$(cd "$(dirname "$0")/.." && pwd)/chatbot"
    mkdir -p "$chatbot_dir"
    print_status "Ensured chatbot directory exists at $chatbot_dir" "Failed to create chatbot directory"
    
    # Create .env file if it doesn't exist
    TELEGRAM_BOT_ENV="$chatbot_dir/.env"
    if [ ! -f "$TELEGRAM_BOT_ENV" ]; then
        print_section "Creating .env file"
        cat > "$TELEGRAM_BOT_ENV" << 'EOL'
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Authentication (add Telegram user IDs separated by commas)
# AUTHORIZED_USERS=123456789,987654321
EOL
        print_status "Created .env file at $TELEGRAM_BOT_ENV" "Failed to create .env file"
        printf "%b\n" "${YELLOW}⚠️  Please update the TELEGRAM_BOT_TOKEN in $TELEGRAM_BOT_ENV${NC}"
    fi
    
    printf "\n%b\n" "${GREEN}✨ Telegram Bot setup completed successfully!${NC}"
    printf "%b\n" "To get started:"
    printf "%b\n" "1. Get a bot token from @BotFather on Telegram"
    printf "%b\n" "2. Update the TELEGRAM_BOT_TOKEN in $TELEGRAM_BOT_ENV"
    printf "%b\n" "3. Run the bot with: python chatbot/telegrambot.py"
}

# Setup AI agents and configuration
setup_aiagents() {
    print_section "Setting Up AI Agents"
    
    # Check if virtual environment is active
    check_virtualenv
    
    # Install required Python packages
    printf "%b\n" "${BLUE}Installing AI agent dependencies...${NC}"
    pip install smolagents python-dotenv
    print_status $? "Installed AI agent dependencies"
    
    # Create AI directory in the project folder
    local ai_dir="$PROJECT_DIR/ai"
    mkdir -p "$ai_dir"
    print_status $? "Created AI directory at $ai_dir"
    
    # Create .env file for AI configuration if it doesn't exist
    local env_file="$ai_dir/.env"
    if [ ! -f "$env_file" ]; then
        cat > "$env_file" << EOL
# AI Agent Configuration
# This file is automatically generated by setup.sh
# Update these values as needed

# HuggingFace Configuration
HUGGINGFACE_TOKEN=your_huggingface_token_here
HUGGINGFACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct

# Agent Configuration
TEMPERATURE=0.7
MAX_TOKENS=2048

# Add any additional AI-related environment variables below
EOL
        print_status $? "Created AI configuration file at $env_file"
        printf "%b\n" "${YELLOW}ℹ️  Please update $env_file with your HuggingFace token and preferred model${NC}"
    else
        printf "%b\n" "${GREEN}✅ AI configuration file already exists at $env_file${NC}"
    fi
    
    # Create a simple test script to verify the setup
    local test_script="$ai_dir/test_ai_setup.py"
    if [ ! -f "$test_script" ]; then
        cat > "$test_script" << 'EOL'
#!/usr/bin/env python3
"""
Test script to verify AI agent setup
"""
import os
from dotenv import load_dotenv

def test_ai_setup():
    print("Testing AI agent setup...")
    
    # Load environment variables
    load_dotenv()
    
    # Get configuration
    token = os.getenv('HUGGINGFACE_TOKEN')
    model = os.getenv('HUGGINGFACE_MODEL')
    
    print(f"HuggingFace Model: {model}")
    print(f"Token available: {'Yes' if token and token != 'your_huggingface_token_here' else 'No (please update .env file)'}")
    print("\nAI agent setup test completed!")

if __name__ == "__main__":
    test_ai_setup()
EOL
        chmod +x "$test_script"
        print_status $? "Created test script at $test_script"
    fi
    
    printf "%b\n" "${GREEN}✅ AI agent setup completed successfully!${NC}"
    printf "%b\n" "  To test the setup, run: python $test_script"
    printf "%b\n" "  Don't forget to update your HuggingFace token in $env_file"
}

# Run the main function with all arguments
main "$@"
