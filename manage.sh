#!/bin/bash

# Storage Node Management Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}Error: .env file not found. Run setup.sh first.${NC}"
    exit 1
fi

# Function to check if container is running
check_container() {
    if [ "$(docker ps -q -f name=${NODE_NAME})" ]; then
        return 0
    else
        return 1
    fi
}

# Function to display service status
show_status() {
    if check_container; then
        echo -e "${GREEN}Storage Node Status:${NC}"
        docker exec ${NODE_NAME} supervisorctl status
        echo -e "\n${YELLOW}Container Resources:${NC}"
        docker stats ${NODE_NAME} --no-stream
        echo -e "\n${YELLOW}Mounted Volumes:${NC}"
        docker inspect -f '{{ range .Mounts }}{{ .Source }} -> {{ .Destination }}{{ println }}{{ end }}' ${NODE_NAME}
    else
        echo -e "${RED}Storage node is not running${NC}"
        exit 1
    fi
}

# Function to show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        docker compose logs -f
    else
        if check_container; then
            docker exec ${NODE_NAME} supervisorctl tail -f $service
        else
            echo -e "${RED}Storage node is not running${NC}"
            exit 1
        fi
    fi
}

# Function to restart services
restart_service() {
    local service=$1
    if [ -z "$service" ]; then
        echo -e "${RED}Error: Service name required${NC}"
        exit 1
    fi
    
    if check_container; then
        echo -e "${YELLOW}Restarting $service...${NC}"
        docker exec ${NODE_NAME} supervisorctl restart $service
        echo -e "${GREEN}Service restarted${NC}"
    else
        echo -e "${RED}Storage node is not running${NC}"
        exit 1
    fi
}

# Function to check disk usage
check_disk() {
    if check_container; then
        echo -e "${YELLOW}Disk Usage:${NC}"
        docker exec ${NODE_NAME} df -h /shared /backups /public
    else
        echo -e "${RED}Storage node is not running${NC}"
        exit 1
    fi
}

# Function to check network connectivity
check_network() {
    if check_container; then
        echo -e "${YELLOW}Network Status:${NC}"
        echo -e "\n${GREEN}Open Ports:${NC}"
        docker exec ${NODE_NAME} netstat -tulpn
        echo -e "\n${GREEN}ZeroTier Status:${NC}"
        docker exec ${NODE_NAME} zerotier-cli status
    else
        echo -e "${RED}Storage node is not running${NC}"
        exit 1
    fi
}

# Function to setup directories and permissions
setup_directories() {
    echo -e "${YELLOW}Setting up directories and permissions...${NC}"
    
    # Create main directories
    mkdir -p ./shared
    mkdir -p ./backups
    mkdir -p ./public
    
    # Create config directories
    mkdir -p ./config/syncthing/${NODE_NAME}
    mkdir -p ./config/samba/${NODE_NAME}
    mkdir -p ./config/nfs/${NODE_NAME}
    mkdir -p ./config/mosquitto/${NODE_NAME}/{data,log}
    mkdir -p ./config/zerotier/${NODE_NAME}
    mkdir -p ./config/samba/${NODE_NAME}/log
    
    # Set permissions for Syncthing
    chown -R 1000:1000 ./config/syncthing/${NODE_NAME}
    chmod -R 755 ./config/syncthing/${NODE_NAME}
    
    # Set permissions for shared directories
    chmod -R 755 ./shared ./backups ./public
    
    # Create default Samba config if it doesn't exist
#    if [ ! -f "./config/samba/${NODE_NAME}/smb.conf" ]; then
#        cat > "./config/samba/${NODE_NAME}/smb.conf" << 'EOL'
#[global]
#   workgroup = WORKGROUP
#   server string = %h server
#   security = user
#   map to guest = Bad User
#   log file = /var/log/samba/log.%m
#   max log size = 50

#[public]
#   path = /public
#   browseable = yes
#   read only = no
#   guest ok = yes
#   create mask = 0644
#   directory mask = 0755

#[shared]
#   path = /shared
#   browseable = yes
#   read only = no
#   guest ok = no
#   create mask = 0644
#   directory mask = 0755
#EOL
#    fi
    
    # Create default Mosquitto config if it doesn't exist
#    if [ ! -f "./config/mosquitto/${NODE_NAME}/mosquitto.conf" ]; then
#        cat > "./config/mosquitto/${NODE_NAME}/mosquitto.conf" << 'EOL'
#listener 1883
#allow_anonymous true
#persistence true
#persistence_location /var/lib/mosquitto/
#log_dest file /var/log/mosquitto/mosquitto.log
#EOL
#    fi
    
    # Set proper permissions for config files
#    chmod 644 "./config/samba/${NODE_NAME}/smb.conf"
#    chmod 644 "./config/mosquitto/${NODE_NAME}/mosquitto.conf"
    
    echo -e "${GREEN}Directory setup complete${NC}"
}

# Help message
show_help() {
    echo -e "Storage Node Management Script"
    echo -e "\nUsage: $0 [command] [options]"
    echo -e "\nCommands:"
    echo -e "  start         Start the storage node"
    echo -e "  stop          Stop the storage node"
    echo -e "  restart       Restart the storage node"
    echo -e "  status        Show service status"
    echo -e "  logs [svc]    Show logs (optional: specify service name)"
    echo -e "  restart-svc   Restart a specific service"
    echo -e "  disk          Show disk usage"
    echo -e "  network       Show network status"
    echo -e "  help          Show this help message"
}

# Main script logic
case "$1" in
    start)
        echo -e "${YELLOW}Starting storage node...${NC}"
        setup_directories
        docker compose up -d
        echo -e "${GREEN}Storage node started${NC}"
        ;;
    stop)
        echo -e "${YELLOW}Stopping storage node...${NC}"
        docker compose down
        echo -e "${GREEN}Storage node stopped${NC}"
        ;;
    restart)
        echo -e "${YELLOW}Restarting storage node...${NC}"
        docker compose down
        setup_directories
        docker compose up -d
        echo -e "${GREEN}Storage node restarted${NC}"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs $2
        ;;
    restart-svc)
        restart_service $2
        ;;
    disk)
        check_disk
        ;;
    network)
        check_network
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Error: Unknown command${NC}"
        show_help
        exit 1
        ;;
esac

exit 0
