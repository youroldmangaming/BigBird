# Storage Node Configuration Guide

[← Back to Index](README.md) | [Architecture Guide](ARCHITECTURE.md) | [Service Configuration →](SERVICE_CONFIGURATION.md)

---

## Table of Contents
- [Environment Variables](#environment-variables)
- [Docker Configuration](#docker-configuration)
- [Service Configuration](#service-configuration)
- [Network Configuration](#network-configuration)
- [Storage Configuration](#storage-configuration)
- [Security Configuration](#security-configuration)
- [Monitoring Configuration](#monitoring-configuration)
- [Backup Configuration](#backup-configuration)

## Configuration Files Overview

```
storage-node/
├── .env                    # Environment variables
├── supervisord.conf        # Service supervision
├── exports                 # NFS exports
├── smb.conf               # Samba configuration
└── docker-compose.yml     # Container configuration
```

## Environment Variables (.env)

### Core Settings
```ini
# Node Identification
NODE_NAME=storage-node-1
ZEROTIER_NETWORK_ID=

# Directory Paths
SHARED_DIR=./shared
BACKUPS_DIR=./backups
PUBLIC_DIR=./public
LOG_DIR=./var/log

# Service Ports
SAMBA_PORT=445
NFS_PORT=2049
SYNCTHING_PORT=22000
MQTT_PORT=1883
ZEROTIER_PORT=9993

# Logging
LOG_LEVEL=INFO
```

### Optional Settings
```ini
# Performance Tuning
NFS_THREADS=8
SYNCTHING_MAX_RECV_KB=0
MQTT_MAX_CONNECTIONS=100

# Security
ENABLE_AUTH=true
REQUIRE_SECURE=true
```

## Service Configurations

### 1. NFS Configuration (exports)
```
# Format: directory client_spec(options)
/shared *(rw,sync,no_subtree_check,no_root_squash,insecure,fsid=0)
/backups *(rw,sync,no_subtree_check,no_root_squash,insecure,fsid=1)
/public *(rw,sync,no_subtree_check,no_root_squash,insecure,fsid=2)
```

#### NFS Options Explained
- `rw`: Read-write access
- `sync`: Synchronous writes
- `no_subtree_check`: Disable subtree checking
- `no_root_squash`: Allow root access
- `insecure`: Allow connections from ports > 1024
- `fsid`: Unique filesystem ID

### 2. Samba Configuration (smb.conf)
```ini
[global]
workgroup = WORKGROUP
server string = Storage Node
security = user
map to guest = Bad User
guest account = nobody

[shared]
path = /shared
browseable = yes
writable = yes
guest ok = yes
create mask = 0777
directory mask = 0777

[backups]
path = /backups
browseable = yes
writable = yes
guest ok = yes
create mask = 0777
directory mask = 0777

[public]
path = /public
browseable = yes
writable = yes
guest ok = yes
create mask = 0777
directory mask = 0777
```

### 3. Supervisord Configuration (supervisord.conf)
```ini
[supervisord]
nodaemon=true
user=root

[program:rpcbind]
command=/usr/sbin/rpcbind -f
priority=10
autorestart=true

[program:nfs]
command=/usr/sbin/rpc.nfsd --no-nfs-version 2 --no-nfs-version 3 --debug 8
priority=20
autorestart=true

[program:mountd]
command=/usr/sbin/rpc.mountd --foreground --no-nfs-version 2 --no-nfs-version 3 --debug all
priority=30
autorestart=true

[program:smbd]
command=/usr/sbin/smbd --foreground --no-process-group
priority=40
autorestart=true

[program:syncthing]
command=/usr/bin/syncthing --no-browser --no-restart --logflags=0
priority=50
autorestart=true

[program:zerotier]
command=/usr/sbin/zerotier-one
priority=60
autorestart=true

[program:mosquitto]
command=/usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf
priority=70
autorestart=true

[program:monitor]
command=python3 /usr/local/bin/monitor.py
priority=100
autorestart=true
```

### 4. Docker Compose Configuration (docker-compose.yml)
```yaml
version: '3.8'

services:
  storage-node:
    image: storage-node
    container_name: ${NODE_NAME}
    privileged: true
    network_mode: host
    volumes:
      - ${SHARED_DIR}:/shared
      - ${BACKUPS_DIR}:/backups
      - ${PUBLIC_DIR}:/public
      - ${LOG_DIR}:/var/log
      - ./supervisord.conf:/etc/supervisor/conf.d/supervisord.conf
      - ./monitor.py:/usr/local/bin/monitor.py
    env_file:
      - .env
    ports:
      - "${SAMBA_PORT}:445"
      - "${NFS_PORT}:2049"
      - "${SYNCTHING_PORT}:22000"
      - "${MQTT_PORT}:1883"
      - "${ZEROTIER_PORT}:9993/udp"
    restart: unless-stopped
```

## Security Configuration

### 1. File Permissions
```bash
# Default permissions
chmod -R 777 shared backups public
chmod -R 755 var/log

# Restricted permissions (optional)
chmod -R 750 shared backups
chmod -R 777 public
```

### 2. Network Security
- Use ZeroTier for secure remote access
- Configure firewall rules
- Implement user authentication

### 3. Service Security
```ini
# NFS: Restrict to specific networks
/shared 192.168.1.0/24(rw,sync)

# Samba: Enable user authentication
security = user
map to guest = Never

# Syncthing: Device authentication only
```

## Performance Tuning

### 1. NFS Performance
```
# Increase threads
NFS_THREADS=16

# Optimize mount options
rsize=1048576
wsize=1048576
```

### 2. Samba Performance
```ini
socket options = TCP_NODELAY IPTOS_LOWDELAY
read raw = yes
write raw = yes
max xmit = 65535
dead time = 15
getwd cache = yes
```

### 3. Syncthing Performance
```
# Adjust receive buffer
SYNCTHING_MAX_RECV_KB=4096

# Optimize scan interval
rescanIntervalS=3600
```

## Monitoring Configuration

### 1. Log Levels
```ini
# Available levels: DEBUG, INFO, WARNING, ERROR
LOG_LEVEL=INFO
```

### 2. Alert Thresholds
```python
# monitor.py settings
DISK_USAGE_THRESHOLD = 90
MEMORY_USAGE_THRESHOLD = 85
SERVICE_RESTART_THRESHOLD = 3
```

### 3. MQTT Topics
```
storage/status/#    # Status updates
storage/alerts/#    # System alerts
storage/control/#   # Control messages
```

## Advanced Configuration

### 1. Custom Scripts
- Place in `/usr/local/bin/`
- Make executable with `chmod +x`
- Add to supervisord.conf if needed

### 2. Backup Configuration
```bash
# Backup paths
/etc/exports
/etc/samba/smb.conf
/etc/supervisor/conf.d/supervisord.conf
.env
```

### 3. Recovery Options
```bash
# Configuration backup
tar -czf config-backup.tar.gz \
    /etc/exports \
    /etc/samba/smb.conf \
    /etc/supervisor/conf.d/supervisord.conf \
    .env
