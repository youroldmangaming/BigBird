# Storage Node Quick Start Guide

[← Back to Index](README.md) | [Installation Guide →](INSTALLATION.md)

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Basic Configuration](#basic-configuration)
- [Start Services](#start-services)
- [Access Services](#access-services)
- [Basic Management](#basic-management)
- [Common Tasks](#common-tasks)

## 1. Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Python 3.8+
- Git
- 4GB RAM minimum
- 20GB storage minimum

## 2. Installation

```bash
# Clone repository
git clone <repository-url>
cd storage-node

# Run setup
./setup.sh
```

## 3. Basic Configuration

```bash
# Copy example config
cp .env.example .env

# Edit configuration
NODE_NAME=storage-1
ZEROTIER_NETWORK_ID=your_network_id
SHARED_DIR=/path/to/shared
BACKUPS_DIR=/path/to/backups
```

## 4. Start Services

```bash
# Start all services
./manage.sh start

# Check status
./manage.sh status
```

## 5. Access Services

### NFS Access
```bash
# Mount NFS share
mount -t nfs <node-ip>:/shared /mnt/storage
```

### Samba Access
```bash
# Windows: \\<node-ip>\shared
# macOS: smb://<node-ip>/shared
# Linux: mount -t cifs //<node-ip>/shared /mnt/storage
```

### Syncthing Access
```bash
# Web UI: http://<node-ip>:8384
# Default credentials in .env file
```

## 6. Basic Management

```bash
# View logs
./manage.sh logs

# Stop services
./manage.sh stop

# Restart services
./manage.sh restart

# Update services
./manage.sh update
```

## 7. Common Tasks

### Add User
```bash
# Add Samba user
./manage.sh add-user username

# Set permissions
./manage.sh set-permissions username
```

### Backup Data
```bash
# Create backup
./manage.sh backup

# List backups
./manage.sh list-backups
```

### Monitor Status
```bash
# Check health
./manage.sh health

# View metrics
./manage.sh metrics
```

## 8. Next Steps

1. Read full documentation:
   - SECURITY.md - Security configuration
   - MONITORING.md - Monitoring setup
   - NETWORKING.md - Network configuration
   - TROUBLESHOOTING.md - Common issues

2. Configure security:
   - Enable encryption
   - Set up authentication
   - Configure firewall

3. Set up monitoring:
   - Enable alerts
   - Configure logging
   - Set up dashboard

## 9. Troubleshooting

### Service Issues
```bash
# Check service status
./manage.sh status <service>

# View service logs
./manage.sh logs <service>

# Restart service
./manage.sh restart <service>
```

### Network Issues
```bash
# Check ZeroTier
./manage.sh network-status

# Test connectivity
./manage.sh network-test

# Reset network
./manage.sh reset-network
```

### Storage Issues
```bash
# Check space
./manage.sh disk-usage

# Verify permissions
./manage.sh check-permissions

# Fix permissions
./manage.sh fix-permissions
```

## 10. Getting Help

1. Check logs:
```bash
./manage.sh logs
./manage.sh debug-info
```

2. Common solutions:
   - Restart services
   - Check permissions
   - Verify network
   - Review logs

3. Support resources:
   - Documentation
   - Issue tracker
   - Community forum

## 11. Best Practices

1. Regular Maintenance
   - Update regularly
   - Monitor resources
   - Check logs
   - Test backups

2. Security
   - Strong passwords
   - Regular updates
   - Access control
   - Encryption

3. Performance
   - Monitor usage
   - Optimize settings
   - Balance load
   - Clean old data
