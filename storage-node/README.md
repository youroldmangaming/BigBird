# Storage Node (Beta 1)

A comprehensive multi-service Docker container for network storage and synchronization.

**Status**: Beta 1 Release
- Complete core functionality
- Comprehensive documentation
- Production-ready with standard security measures
- Actively seeking feedback and testing

## Documentation Index

### Getting Started
- [Quick Start Guide](QUICKSTART.md)
- [Installation Guide](INSTALLATION.md)
- [Configuration Guide](CONFIGURATION.md)

### Core Documentation
- [Architecture Overview](ARCHITECTURE.md)
- [System Design](DESIGN.md)
- [Service Configuration](SERVICE_CONFIGURATION.md)
- [Command Reference](COMMANDS.md)

### Operation Guides
- [Maintenance Guide](MAINTENANCE.md)
- [Monitoring Guide](MONITORING.md)
- [Backup & Recovery](BACKUP.md)
- [Networking Guide](NETWORKING.md)

### Development & Troubleshooting
- [Development Guide](DEVELOPMENT.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

## Beta 1 Features

### Core Services
- NFS v4 file sharing
- Samba/SMB file sharing
- Syncthing P2P synchronization
- ZeroTier software-defined networking
- MQTT service discovery

### Management Features
- Comprehensive command-line interface
- Docker-based deployment
- Environment-driven configuration
- Automated service management
- Integrated monitoring
- Backup and recovery tools

### Security Features
- ZeroTier network encryption
- Service authentication
- Configurable access controls
- Secure default settings
- Audit logging

### Documentation
- Complete user guides
- Architecture documentation
- Development guidelines
- Troubleshooting procedures
- Best practices

## Prerequisites

- Docker Engine
- Docker Compose
- Python 3.x (for monitoring)
- Bash shell

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd storage-node
```

2. Run the setup script:
```bash
./setup.sh [zerotier-network-id]
```
The setup script will:
- Create necessary directories
- Generate .env configuration
- Build the Docker image
- Configure services
- Set appropriate permissions

3. Start the storage node:
```bash
./manage.sh start
```

## Configuration

### Environment Variables (.env)

The `.env` file contains all configuration options:

```ini
# Storage Node Configuration
NODE_NAME=storage-node-1
ZEROTIER_NETWORK_ID=

# Shared Directory Paths
SHARED_DIR=./shared
BACKUPS_DIR=./backups
PUBLIC_DIR=./public

# Service Ports
SAMBA_PORT=445
NFS_PORT=2049
SYNCTHING_PORT=22000
MQTT_PORT=1883
ZEROTIER_PORT=9993

# Log Configuration
LOG_LEVEL=INFO
LOG_DIR=./var/log
```

### Directory Structure

```
storage-node/
├── shared/           # Primary storage
├── backups/         # Backup storage
├── public/          # Public access
├── var/
│   └── log/        # Service logs
├── Dockerfile.storage
├── docker-compose.yml
├── setup.sh
├── manage.sh
├── monitor.py
├── supervisord.conf
└── .env
```

## Management

The `manage.sh` script provides comprehensive management capabilities:

```bash
# Show available commands
./manage.sh help

# Common commands:
./manage.sh start          # Start the storage node
./manage.sh stop           # Stop the storage node
./manage.sh restart        # Restart the storage node
./manage.sh status         # Show service status
./manage.sh logs [service] # View logs (optional: specify service)
./manage.sh disk          # Check disk usage
./manage.sh network       # Check network status
```

## Monitoring

The `monitor.py` script provides real-time monitoring of:
- Service health
- Disk usage
- Network connectivity
- System resources

### Start Monitoring

```bash
# Start monitoring in the background
docker exec storage-node python3 /usr/local/bin/monitor.py &

# View monitoring logs
docker exec storage-node tail -f /var/log/storage-monitor.log
```

### MQTT Topics

Monitor services via MQTT:
- `storage/status/<service>` - Service status updates
- `storage/alerts/disk` - Disk usage alerts
- `storage/alerts/network` - Network connectivity alerts
- `storage/status` - Overall system status

## Service Access

### NFS Mounts

```bash
# Linux/macOS
mount -t nfs -o vers=4 <host-ip>:/shared /mnt/shared

# Windows
mount -o vers=4 \\<host-ip>\shared Z:
```

### Samba Shares

```bash
# Linux/macOS
mount -t cifs //<host-ip>/shared /mnt/shared

# Windows
net use Z: \\<host-ip>\shared
```

### Syncthing

Access the web interface:
```
http://<host-ip>:22000/
```

### ZeroTier

Join the network:
```bash
zerotier-cli join <network-id>
```

## Troubleshooting

### Common Issues

1. NFS Mount Fails
```bash
# Check NFS service
./manage.sh restart-svc nfs
./manage.sh logs nfs
```

2. Network Connectivity
```bash
# Check network status
./manage.sh network
```

3. Disk Space Issues
```bash
# Check disk usage
./manage.sh disk
```

### Log Access

View specific service logs:
```bash
./manage.sh logs rpcbind    # NFS/RPC logs
./manage.sh logs smbd       # Samba logs
./manage.sh logs syncthing  # Syncthing logs
./manage.sh logs zerotier   # ZeroTier logs
```

## Security Considerations

1. File Permissions
   - Shared directories: 777 (full access)
   - Log directories: 755 (restricted access)

2. Network Security
   - Use ZeroTier for secure remote access
   - Configure firewall rules as needed
   - Consider implementing user authentication

3. Service Security
   - NFS: Configured for NFSv4 only
   - Samba: Consider adding user authentication
   - Syncthing: Uses device ID authentication

## Maintenance

### Regular Tasks

1. Update Services
```bash
docker-compose pull
docker-compose up -d
```

2. Backup Configuration
```bash
./manage.sh backup
```

3. Check Logs
```bash
./manage.sh logs
```

4. Monitor Resources
```bash
./manage.sh status
```

## Feedback and Support

We welcome feedback and contributions! Please:
1. Report issues through the issue tracker
2. Submit feature requests
3. Share your deployment experiences
4. Contribute improvements
