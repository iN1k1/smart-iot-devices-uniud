#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting InfluxDB Setup...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if InfluxDB container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^influxdb$'; then
    echo -e "${YELLOW}⚠️  InfluxDB container already exists.${NC}"
    read -p "   Do you want to remove the existing container? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Removing existing InfluxDB container...${NC}"
        docker stop influxdb > /dev/null
        docker rm influxdb > /dev/null
    else
        echo -e "${YELLOW}❌ Setup cancelled.${NC}"
        exit 1
    fi
fi

# Start InfluxDB container
echo -e "\n${BLUE}🐳 Starting InfluxDB 1.8 container...${NC}"

docker run -d -p 8086:8086 \
  -e INFLUXDB_DB=defaultdb \
  -e INFLUXDB_ADMIN_ENABLED=true \
  -e INFLUXDB_ADMIN_USER=admin \
  -e INFLUXDB_ADMIN_PASSWORD=adminpass \
  -e INFLUXDB_USER=user \
  -e INFLUXDB_USER_PASSWORD=userpass \
  --name=influxdb \
  -v influxdb:/var/lib/influxdb \
  influxdb:1.8

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ InfluxDB is now running!${NC}"
    echo -e "\n${BLUE}🔌 Connection Details:${NC}"
    echo -e "   - Web Interface: ${GREEN}http://localhost:8086${NC}"
    echo -e "   - Admin Username: ${GREEN}admin${NC}"
    echo -e "   - Admin Password: ${GREEN}adminpass${NC}"
    echo -e "   - Regular User: ${GREEN}user${NC}"
    echo -e "   - User Password: ${GREEN}userpass${NC}"
    echo -e "   - Default Database: ${GREEN}defaultdb${NC}"
else
    echo -e "\n${YELLOW}❌ Failed to start InfluxDB container.${NC}"
    exit 1
fi

# Set up Python environment
echo -e "\n${BLUE}🐍 Setting up Python environment...${NC}"

# Ensuring we are in the right virtual environment
echo -e "${BLUE}🔄 Activating virtual environment...${NC}"
source siotd/bin/activate

# Install Python package
echo -e "\n${BLUE}📦 Installing Python dependencies...${NC}"
pip3 install influxdb

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Successfully installed influxdb-python package${NC}"
else
    echo -e "\n${YELLOW}⚠️  Failed to install influxdb-python package. You may need to install it manually.${NC}"
fi

# Print final instructions
echo -e "\n${GREEN}🎉 Setup completed!${NC}"
