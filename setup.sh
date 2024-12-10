#!/bin/bash

# Storage Node Setup Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to check if a user exists
user_exists() {
    id "$1" &>/dev/null
}

shared_folder=""
# Function to check if the shared folder exists
shared_folder_exists() {
    [ -d "$1" ]
}

# Prompt for the user account and check until valid input is provided
while true; do
    read -p "Enter the username of the account that has the shared folder: " username

    # Check if the user exists
    if user_exists "$username"; then
        # Define the path to the shared folder
        shared_folder="/home/$username/shared"

        # Check if the shared folder exists
        if shared_folder_exists "$shared_folder"; then
            echo "The shared folder for user '$username' is located at: $shared_folder"
            break  # Exit the loop if both checks are successful
        else
            echo "The shared folder for user '$username' does not exist. Please try again."
        fi
    else
        echo "User '$username' does not exist. Please try again."
    fi
done




# Check for .env file and create if it doesn't exist
if [ ! -f .env ]; then
    echo -e "\n${YELLOW}Creating .env file...${NC}"
    cat > .env << EOL
# Storage Node Configuration
NODE_NAME=storage-node-1

ZEROTIER_NETWORK_ID=1d71939404640f20
ZEROTIER_TOKEN=8dZCe3xyG4FBqp9uFir7nfx9yFP7i2jx
ZEROTIER_PORT=9993

# Shared Directory Paths
SHARED_DIR={$shared_folder}
BACKUPS_DIR=./backups
PUBLIC_DIR=./public
SYNC_INTERVAL=300

# Service Ports
SAMBA_PORT=445
NFS_PORT=2049
SYNCTHING_PORT=22000
MQTT_PORT=1883

# Log Configuration
LOG_LEVEL=INFO
LOG_DIR=./var/log
EOL
    echo -e "${GREEN}.env file created${NC}"
else
    echo -e "${YELLOW}Using existing .env file${NC}"
fi

# Load environment variables
set -a
source .env
set +a

echo -e "${GREEN}Starting Storage Node Setup...${NC}"

# Create necessary directories
echo -e "\n${YELLOW}Creating directories...${NC}"
mkdir -p "${SHARED_DIR#./}" "${BACKUPS_DIR#./}" "${PUBLIC_DIR#./}"
mkdir -p "${LOG_DIR#./}/supervisor"

# Set directory permissions
echo -e "\n${YELLOW}Setting directory permissions...${NC}"
chmod -R 777 "${SHARED_DIR#./}" "${BACKUPS_DIR#./}" "${PUBLIC_DIR#./}"
chmod -R 755 "${LOG_DIR#./}"

# Build Docker image
echo -e "\n${YELLOW}Building Docker image...${NC}"
if docker build -t storage-node -f Dockerfile.storage .; then
    echo -e "${GREEN}Docker image built successfully${NC}"
else
    echo -e "${RED}Failed to build Docker image${NC}"
    exit 1
fi

# Make monitor.py executable
chmod +x monitor.py

# Create docker-compose.yml if it doesn't exist
if [ ! -f docker-compose.yml ]; then
    echo -e "\n${YELLOW}Creating docker-compose.yml...${NC}"
    cat > docker-compose.yml << EOL
version: '3.8'

services:
  storage-node:
    image: storage-node
    container_name: \${NODE_NAME}
    privileged: true
    network_mode: host
    volumes:
      - \${SHARED_DIR}:/shared
      - \${BACKUPS_DIR}:/backups
      - \${PUBLIC_DIR}:/public
      - \${LOG_DIR}:/var/log
      - ./supervisord.conf:/etc/supervisor/conf.d/supervisord.conf
      - ./monitor.py:/usr/local/bin/monitor.py
    env_file:
      - .env
    ports:
      - "\${SAMBA_PORT}:445"
      - "\${NFS_PORT}:2049"
      - "\${SYNCTHING_PORT}:22000"
      - "\${MQTT_PORT}:1883"
      - "\${ZEROTIER_PORT}:9993/udp"
    restart: unless-stopped
EOL
fi

# Update ZeroTier network ID if provided
if [ ! -z "$1" ]; then
    echo -e "\n${YELLOW}Setting ZeroTier network ID...${NC}"
    sed -i '' "s/ZEROTIER_NETWORK_ID=/ZEROTIER_NETWORK_ID=$1/" .env
fi

echo -e "\n${GREEN}Setup complete!${NC}"
echo -e "\nTo start the storage node, run:"
echo -e "${YELLOW}docker-compose up -d${NC}"
echo -e "\nTo view logs:"
echo -e "${YELLOW}docker-compose logs -f${NC}"
echo -e "\nTo stop the storage node:"
echo -e "${YELLOW}docker-compose down${NC}"

# Create .gitignore
echo -e "\n${YELLOW}Creating .gitignore...${NC}"
cat > .gitignore << EOL
shared/
backups/
public/
var/
*.log
.env
EOL

echo -e "\n${GREEN}Setup script completed successfully!${NC}"
