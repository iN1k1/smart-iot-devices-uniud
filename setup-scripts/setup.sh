#!/bin/sh

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to run a setup script
run_setup() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        printf "%b\n" "${RED}❌ Error: $script_name not found in $SCRIPT_DIR${NC}" >&2
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi
    
    printf "%b\n" "${BLUE}🚀 Running $script_name...${NC}"
    
    # Run the script in its own directory to handle relative paths correctly
    (cd "$SCRIPT_DIR" && "./$script_name")
    
    if [ $? -ne 0 ]; then
        printf "%b\n" "${RED}❌ $script_name failed${NC}" >&2
        return 1
    fi
    
    printf "%b\n" "${GREEN}✅ $script_name completed successfully${NC}"
    return 0
}

# Main execution
printf "%b\n" "${BLUE}========================================${NC}"
printf "%b\n" "${BLUE}🚀 Starting Smart IoT Devices Setup${NC}"
printf "%b\n" "${BLUE}========================================${NC}"

# 1. First, run the environment setup
run_setup "env_setup.sh" || exit 1

# 2. Run other setup scripts in the recommended order
run_setup "mosquitto_setup.sh" || exit 1
run_setup "influx_db_setup.sh" || exit 1
run_setup "grafana_setup.sh" || exit 1
run_setup "adafruit_setup.sh" || exit 1
run_setup "telegrambot_setup.sh" || exit 1

printf "%b\n" "${GREEN}✨ All setup scripts completed successfully!${NC}"
printf "%b\n" "${BLUE}========================================${NC}"
printf "%b\n" "${GREEN}🚀 Smart IoT Devices setup is complete!${NC}"
printf "%b\n" "${BLUE}========================================${NC}"

exit 0
