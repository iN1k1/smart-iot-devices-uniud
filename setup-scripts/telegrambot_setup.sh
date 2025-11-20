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

printf "%b\n" "${BLUE}🚀 Starting Telegram Bot Setup...${NC}"

# Verify virtual environment
print_section "Verifying virtual environment"
if [ -z "$VIRTUAL_ENV" ] || [ ! -d "$VIRTUAL_ENV" ]; then
    printf "%b\n" "${RED}❌ Virtual environment not found at $VENV_DIR${NC}" >&2
    printf "%b\n" "${YELLOW}Please run setup-scripts/env_setup.sh first${NC}" >&2
    exit 1
fi
print_status "Using virtual environment at $VIRTUAL_ENV" "Failed to find virtual environment"

# Install required packages
print_section "Installing Python packages"
if pip install python-telegram-bot python-dotenv; then
    print_status "Successfully installed Python packages" "Failed to install Python packages"
else
    printf "%b\n" "${RED}❌ Failed to install Python packages${NC}" >&2
    exit 1
fi

# Create .env file if it doesn't exist
TELEGRAM_BOT_ENV="$(cd "$(dirname "$0")/../chatbot" && pwd)/.env"
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

exit 0
