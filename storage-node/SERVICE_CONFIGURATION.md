# Storage Node Service Configuration Guide

[← Back to Index](README.md) | [Networking Guide](NETWORKING.md) | [Commands Reference →](COMMANDS.md)

---

## Table of Contents
- [Service Overview](#service-overview)
- [NFS Configuration](#nfs-configuration)
- [Samba Configuration](#samba-configuration)
- [Syncthing Configuration](#syncthing-configuration)
- [MQTT Configuration](#mqtt-configuration)
- [ZeroTier Configuration](#zerotier-configuration)
- [Supervisor Configuration](#supervisor-configuration)
- [Environment Variables](#environment-variables)
- [Service Dependencies](#service-dependencies)
- [Resource Limits](#resource-limits)
- [Service Integration](#service-integration)
- [Best Practices](#best-practices)

## Service Overview

| Service    | Default Port | Protocol | Purpose                    |
|------------|-------------|----------|----------------------------|
| NFS        | 2049        | TCP      | Network File System        |
| Samba      | 445         | TCP      | Windows File Sharing       |
| Syncthing  | 22000       | TCP      | P2P File Synchronization  |
| MQTT       | 1883        | TCP      | Message Queue             |
| ZeroTier   | 9993        | UDP      | Network Overlay           |

## NFS Configuration

### Basic Setup
```bash
# /etc/exports
/shared        192.168.1.0/24(rw,sync,no_subtree_check)
/backups       192.168.1.0/24(rw,sync,no_subtree_check)
/public        *(ro,all_squash,no_subtree_check)
```

### Advanced Options
```bash
# High-performance settings
/shared        192.168.1.0/24(rw,sync,no_subtree_check,async,no_wdelay)
/backups       192.168.1.0/24(rw,sync,no_subtree_check,async,no_wdelay)
```

### Security Options
```bash
# Secure configuration
/shared        192.168.1.0/24(rw,sync,root_squash,all_squash,secure)
/backups       192.168.1.0/24(rw,sync,root_squash,all_squash,secure)
```

## Samba Configuration

### Basic Setup
```ini
[global]
workgroup = WORKGROUP
server string = Storage Node
security = user
map to guest = Bad Password

[shared]
path = /shared
browseable = yes
writable = yes
guest ok = no
valid users = @storage
```

### Advanced Options
```ini
[global]
# Performance tuning
socket options = TCP_NODELAY IPTOS_LOWDELAY
read raw = yes
write raw = yes
max xmit = 65535
dead time = 15
getwd cache = yes

# Security settings
encrypt passwords = yes
smb encrypt = required
```

### Share Templates
```ini
# Private share
[private]
path = /shared/private
valid users = @storage
writable = yes
browseable = no
guest ok = no

# Public share
[public]
path = /shared/public
writable = no
browseable = yes
guest ok = yes
```

## Syncthing Configuration

### Basic Setup
```xml
<configuration>
  <folder id="shared">
    <path>/shared</path>
    <type>sendreceive</type>
    <rescanIntervalS>3600</rescanIntervalS>
    <fsWatcherEnabled>true</fsWatcherEnabled>
    <devices>
      <device id="DEVICE-ID-1"></device>
      <device id="DEVICE-ID-2"></device>
    </devices>
  </folder>
</configuration>
```

### Advanced Options
```xml
<configuration>
  <options>
    <globalAnnounceEnabled>false</globalAnnounceEnabled>
    <localAnnounceEnabled>true</localAnnounceEnabled>
    <relaysEnabled>false</relaysEnabled>
    <reconnectionIntervalS>60</reconnectionIntervalS>
    <maxConcurrentIncomingRequestKiB>100000</maxConcurrentIncomingRequestKiB>
  </options>
</configuration>
```

### Ignore Patterns
```
// .stignore
(?d).DS_Store
(?d)._*
(?d).Spotlight-V100
(?d).Trashes
(?d)desktop.ini
(?d)Thumbs.db
```

## MQTT Configuration

### Basic Setup
```conf
# /etc/mosquitto/mosquitto.conf
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
```

### Security Options
```conf
# Enable TLS
listener 8883
cafile /etc/mosquitto/ca.crt
certfile /etc/mosquitto/server.crt
keyfile /etc/mosquitto/server.key
require_certificate true
```

### Access Control
```conf
# ACL configuration
acl_file /etc/mosquitto/acl

# ACL rules
topic read storage/status/#
topic write storage/command/#
topic readwrite storage/data/#
```

## ZeroTier Configuration

### Basic Setup
```bash
# Join network
zerotier-cli join NETWORK_ID

# Allow management
zerotier-cli set NETWORK_ID allowManaged=1
```

### Network Rules
```
# Allow storage traffic
drop
accept ipprotocol tcp dport 445
accept ipprotocol tcp dport 2049
accept ipprotocol tcp dport 22000
accept ipprotocol tcp dport 1883
```

### Advanced Options
```bash
# Performance tuning
zerotier-cli set NETWORK_ID mtu=2800
zerotier-cli set NETWORK_ID multicastLimit=32
```

## Supervisor Configuration

### Service Definitions
```ini
[program:nfs]
command=/usr/sbin/nfsd -d
priority=10
autostart=true
autorestart=true

[program:smbd]
command=/usr/sbin/smbd -F
priority=20
autostart=true
autorestart=true

[program:syncthing]
command=/usr/bin/syncthing
priority=30
autostart=true
autorestart=true
```

### Process Groups
```ini
[group:storage]
programs=nfs,smbd,syncthing
priority=999

[group:network]
programs=zerotier,mosquitto
priority=998
```

## Environment Variables

### Required Variables
```bash
# Node configuration
NODE_NAME=storage-1
ZEROTIER_NETWORK_ID=your_network_id

# Storage paths
SHARED_DIR=/path/to/shared
BACKUPS_DIR=/path/to/backups
PUBLIC_DIR=/path/to/public
```

### Optional Variables
```bash
# Performance tuning
NFS_THREADS=8
SAMBA_MAX_CONNECTIONS=100
SYNCTHING_MAX_SEND_KIB=10000

# Security settings
ENCRYPT_DATA=true
REQUIRE_AUTH=true
ALLOW_GUEST=false
```

## Service Dependencies

### Startup Order
1. Network Services
   - ZeroTier
   - MQTT

2. Storage Services
   - NFS
   - Samba
   - Syncthing

3. Management Services
   - Monitoring
   - Backup

### Health Checks
```bash
# NFS check
showmount -e localhost

# Samba check
smbclient -L localhost

# Syncthing check
curl http://localhost:8384/rest/system/status

# MQTT check
mosquitto_sub -t 'storage/status' -C 1
```

## Resource Limits

### Memory Limits
```ini
# supervisord.conf
[program:nfs]
environment=GOGC=100
stdout_logfile_maxbytes=1MB

[program:smbd]
environment=GOGC=100
stdout_logfile_maxbytes=1MB
```

### Process Limits
```bash
# /etc/security/limits.conf
storage-node soft nofile 65536
storage-node hard nofile 65536
storage-node soft nproc 32768
storage-node hard nproc 32768
```

## Service Integration

### Inter-service Communication
```yaml
services:
  nfs:
    depends_on:
      - zerotier
    environment:
      - NETWORK_READY=true

  samba:
    depends_on:
      - zerotier
    environment:
      - NETWORK_READY=true
```

### Shared Resources
```yaml
volumes:
  shared:
    driver: local
  backups:
    driver: local
  public:
    driver: local
```

## Best Practices

1. Security
   - Enable encryption
   - Use strong authentication
   - Limit network access
   - Regular updates

2. Performance
   - Optimize settings
   - Monitor resources
   - Regular maintenance
   - Load balancing

3. Reliability
   - Regular backups
   - Health monitoring
   - Automatic recovery
   - Error logging
