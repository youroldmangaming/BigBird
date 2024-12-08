# Storage Node Installation Guide

[← Back to Index](README.md) | [Quick Start Guide](QUICKSTART.md) | [Configuration Guide →](CONFIGURATION.md)

---

## Table of Contents
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Platform-Specific Instructions](#platform-specific-instructions)
- [Configuration](#configuration)
- [Post-Installation](#post-installation)
- [Upgrading](#upgrading)
- [Troubleshooting Installation](#troubleshooting-installation)
- [Security Considerations](#security-considerations)
- [Best Practices](#best-practices)

## Quick Start

```bash
# Clone repository
git clone <repository-url>
cd storage-node

# Run setup script
./setup.sh

# Start services
./manage.sh start
```

## Prerequisites

### System Requirements
- CPU: 2+ cores recommended
- RAM: 4GB minimum
- Storage: 20GB minimum for system
- Network: 1Gbps recommended

### Software Requirements
- Docker Engine 20.10+
- Docker Compose 2.0+
- Python 3.8+
- Git

## Installation Methods

### 1. Automated Installation

```bash
# Download installer
curl -O https://raw.githubusercontent.com/storage-node/master/install.sh

# Make executable
chmod +x install.sh

# Run installer
./install.sh
```

### 2. Manual Installation

1. Clone Repository:
```bash
git clone <repository-url>
cd storage-node
```

2. Configure Environment:
```bash
# Copy example config
cp .env.example .env

# Edit configuration
nano .env
```

3. Run Setup:
```bash
# Make scripts executable
chmod +x setup.sh manage.sh

# Run setup
./setup.sh
```

## Platform-Specific Instructions

### Linux (Ubuntu/Debian)

1. Install Dependencies:
```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install requirements
sudo apt install -y \
    docker.io \
    docker-compose \
    python3 \
    python3-pip \
    git
```

2. Configure Docker:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker
```

### macOS

1. Install Dependencies:
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install requirements
brew install docker docker-compose python git
```

2. Configure Docker:
```bash
# Start Docker Desktop
open -a Docker
```

### Windows (WSL2)

1. Install WSL2:
```powershell
# Enable WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine feature
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Set WSL2 as default
wsl --set-default-version 2
```

2. Install Ubuntu:
```powershell
# Install Ubuntu
wsl --install -d Ubuntu

# Launch Ubuntu and follow Linux instructions
wsl
```

## Configuration

### Basic Configuration

1. Environment Variables:
```bash
# Required variables
NODE_NAME=storage-1
ZEROTIER_NETWORK_ID=your_network_id
SHARED_DIR=/path/to/shared
BACKUPS_DIR=/path/to/backups
```

2. Network Configuration:
```bash
# Configure network
./manage.sh setup-network

# Join ZeroTier network
./manage.sh join-network
```

### Advanced Configuration

1. Service Configuration:
```bash
# Configure NFS
./manage.sh configure nfs

# Configure Samba
./manage.sh configure smb

# Configure Syncthing
./manage.sh configure syncthing
```

2. Security Configuration:
```bash
# Set up authentication
./manage.sh configure-auth

# Configure firewall
./manage.sh setup-firewall
```

## Post-Installation

### Verification

1. Check Services:
```bash
# Verify all services
./manage.sh verify-all

# Check individual services
./manage.sh status nfs
./manage.sh status smbd
./manage.sh status syncthing
```

2. Test Access:
```bash
# Test NFS mount
mount -t nfs localhost:/shared /mnt/test

# Test Samba access
smbclient //localhost/shared -U user

# Test Syncthing
curl http://localhost:8384/
```

### Initial Setup

1. Create Users:
```bash
# Add Samba user
./manage.sh add-user username

# Set permissions
./manage.sh set-permissions username
```

2. Configure Backups:
```bash
# Set up backup location
./manage.sh configure-backup

# Test backup
./manage.sh backup-test
```

## Upgrading

### Version Upgrade

1. Backup Configuration:
```bash
# Backup current config
./manage.sh backup-config

# Stop services
./manage.sh stop
```

2. Perform Upgrade:
```bash
# Pull latest changes
git pull

# Run upgrade script
./manage.sh upgrade

# Start services
./manage.sh start
```

### Migration

1. Export Data:
```bash
# Export configuration
./manage.sh export-config

# Backup data
./manage.sh backup-all
```

2. Import Data:
```bash
# Import configuration
./manage.sh import-config

# Restore data
./manage.sh restore-all
```

## Troubleshooting Installation

### Common Issues

1. Docker Issues:
```bash
# Reset Docker
docker system prune -a
docker-compose down -v
docker-compose up -d
```

2. Permission Issues:
```bash
# Fix permissions
./manage.sh fix-permissions

# Reset service user
./manage.sh reset-user
```

3. Network Issues:
```bash
# Check connectivity
./manage.sh network-test

# Reset network
./manage.sh reset-network
```

### Getting Help

1. Gather Information:
```bash
# Generate debug info
./manage.sh debug-info

# Check logs
./manage.sh logs
```

2. Report Issues:
```bash
# Create issue report
./manage.sh report-issue

# Get support
./manage.sh get-help
```

## Security Considerations

1. Initial Hardening:
```bash
# Secure installation
./manage.sh secure-install

# Configure firewall
./manage.sh setup-firewall
```

2. Access Control:
```bash
# Set up authentication
./manage.sh configure-auth

# Review permissions
./manage.sh audit-permissions
```

## Best Practices

1. Installation
   - Use latest stable release
   - Follow platform-specific guides
   - Configure security first
   - Test thoroughly before production

2. Configuration
   - Use secure passwords
   - Enable encryption
   - Configure backups
   - Document settings

3. Maintenance
   - Regular updates
   - Monitor logs
   - Backup configuration
   - Test recovery procedures
