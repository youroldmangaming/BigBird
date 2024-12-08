# Storage Node Networking Guide

[← Back to Index](README.md) | [Configuration Guide](CONFIGURATION.md) | [Service Configuration →](SERVICE_CONFIGURATION.md)

---

## Table of Contents
- [Network Architecture](#network-architecture)
- [ZeroTier Configuration](#zerotier-configuration)
- [Service Ports](#service-ports)
- [Firewall Configuration](#firewall-configuration)
- [Network Security](#network-security)
- [Troubleshooting](#troubleshooting)
- [Performance Tuning](#performance-tuning)

## Network Architecture

### Overview
```
Internet
   │
   ▼
ZeroTier Network
   │
   ├─────────┬─────────┬─────────┐
   ▼         ▼         ▼         ▼
  NFS      Samba   Syncthing   MQTT
(2049)    (445)    (22000)   (1883)
```

## Required Ports

| Service    | Port  | Protocol | Purpose                     |
|------------|-------|----------|----------------------------|
| NFS        | 2049  | TCP      | File system access         |
| Samba      | 445   | TCP      | Windows file sharing       |
| Syncthing  | 22000 | TCP      | P2P synchronization       |
| MQTT       | 1883  | TCP      | Service messaging         |
| ZeroTier   | 9993  | UDP      | Network overlay           |

## Network Configuration

### ZeroTier Setup

1. Join Network:
```bash
# Install ZeroTier
curl -s https://install.zerotier.com | sudo bash

# Join network
zerotier-cli join <network-id>

# Check status
zerotier-cli status
```

2. Network Rules:
```
# zerotier-rules.conf
drop                # Default deny
accept ipprotocol tcp dport 2049  # NFS
accept ipprotocol tcp dport 445   # Samba
accept ipprotocol tcp dport 22000 # Syncthing
accept ipprotocol tcp dport 1883  # MQTT
```

### Firewall Configuration

1. UFW Rules:
```bash
# Allow ZeroTier
ufw allow 9993/udp

# Allow services from ZeroTier network
ufw allow from 172.16.0.0/16 to any port 2049  # NFS
ufw allow from 172.16.0.0/16 to any port 445   # Samba
ufw allow from 172.16.0.0/16 to any port 22000 # Syncthing
ufw allow from 172.16.0.0/16 to any port 1883  # MQTT
```

2. iptables Rules:
```bash
# Allow ZeroTier
iptables -A INPUT -p udp --dport 9993 -j ACCEPT

# Allow services from ZeroTier network
iptables -A INPUT -s 172.16.0.0/16 -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/16 -p tcp --dport 445 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/16 -p tcp --dport 22000 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/16 -p tcp --dport 1883 -j ACCEPT
```

## Service Network Configuration

### NFS Configuration

1. Exports Configuration:
```bash
# /etc/exports
/shared  172.16.0.0/16(rw,sync,no_subtree_check,secure)
/public  172.16.0.0/16(ro,all_squash,no_subtree_check,secure)
```

2. NFS Performance:
```bash
# /etc/sysctl.conf
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
```

### Samba Configuration

1. Network Settings:
```ini
# /etc/samba/smb.conf
[global]
interfaces = zt*
bind interfaces only = yes
smb ports = 445
```

2. Performance Options:
```ini
socket options = TCP_NODELAY IPTOS_LOWDELAY
read raw = yes
write raw = yes
max xmit = 65535
dead time = 15
```

### Syncthing Configuration

1. Network Settings:
```xml
<configuration>
  <options>
    <listenAddress>tcp://0.0.0.0:22000</listenAddress>
    <globalAnnounceEnabled>false</globalAnnounceEnabled>
    <localAnnounceEnabled>true</localAnnounceEnabled>
    <relaysEnabled>false</relaysEnabled>
  </options>
</configuration>
```

2. Discovery Settings:
```xml
<configuration>
  <options>
    <stunServer>off</stunServer>
    <announceLANAddresses>true</announceLANAddresses>
    <reconnectionIntervalS>60</reconnectionIntervalS>
  </options>
</configuration>
```

### MQTT Configuration

1. Network Binding:
```conf
# /etc/mosquitto/mosquitto.conf
listener 1883 0.0.0.0
```

2. Bridge Configuration:
```conf
connection bridge-01
address 172.16.1.2:1883
topic storage/# both 2
```

## Inter-Node Communication

### Node Discovery

1. ZeroTier Discovery:
```bash
# Node advertisement
zerotier-cli listpeers  # List connected peers
zerotier-cli peers      # Show peer details

# Node status
zerotier-cli info      # Local node info
zerotier-cli listnetworks  # Network membership
```

2. MQTT Service Discovery:
```
# Topic structure
storage/nodes/+/status    # Node status updates
storage/nodes/+/services  # Available services
storage/nodes/+/metrics   # Node metrics

# Status message format
{
    "node_id": "storage-1",
    "services": ["nfs", "smb", "syncthing"],
    "status": "online",
    "timestamp": "2024-01-20T10:00:00Z"
}
```

### Service Communication

1. Direct Service Links:
```
Node A (172.16.1.1)        Node B (172.16.1.2)
    │                           │
    ├─── NFS (2049) ───────────┤
    │                           │
    ├─── SMB (445) ────────────┤
    │                           │
    ├─── Syncthing (22000) ────┤
    │                           │
    └─── MQTT (1883) ──────────┘
```

2. Service Discovery Protocol:
```json
{
    "service": "nfs",
    "node": "storage-1",
    "address": "172.16.1.1",
    "port": 2049,
    "status": "active",
    "load": 0.5,
    "peers": ["storage-2", "storage-3"]
}
```

### Data Synchronization

1. File Synchronization:
```
# Syncthing cluster topology
Node A ←→ Node B ←→ Node C
   ↕          ↕         ↕
Node D ←→ Node E ←→ Node F

# Sync configuration
<folder id="shared">
    <device id="NODE-A">
        <address>tcp://172.16.1.1:22000</address>
    </device>
    <device id="NODE-B">
        <address>tcp://172.16.1.2:22000</address>
    </device>
</folder>
```

2. State Synchronization:
```
# MQTT state sync topics
storage/sync/files/+    # File changes
storage/sync/meta/+     # Metadata updates
storage/sync/state/+    # Service state

# State message format
{
    "type": "file_change",
    "path": "/shared/docs",
    "action": "modified",
    "node": "storage-1",
    "timestamp": "2024-01-20T10:00:00Z"
}
```

### Load Balancing

1. Service Distribution:
```
# Load balancing configuration
Node A (Primary)     Node B (Secondary)
├── NFS Primary     ├── NFS Secondary
├── SMB Active      ├── SMB Standby
└── Sync Master     └── Sync Replica

# Health check message
{
    "node": "storage-1",
    "role": "primary",
    "load": {
        "cpu": 0.3,
        "memory": 0.5,
        "disk": 0.4
    }
}
```

2. Failover Protocol:
```
# Node status monitoring
storage/health/+/status   # Node health
storage/health/+/load     # Load metrics
storage/health/+/alerts   # Health alerts

# Failover sequence
1. Detect primary failure
2. Elect new primary
3. Update service routing
4. Notify cluster nodes
```

### Security Coordination

1. Trust Management:
```
# Node authentication
storage/auth/+/challenge  # Auth challenges
storage/auth/+/response   # Auth responses
storage/auth/+/verify    # Verification

# Trust message format
{
    "node": "storage-1",
    "pubkey": "BASE64_KEY",
    "signature": "BASE64_SIG",
    "timestamp": "2024-01-20T10:00:00Z"
}
```

2. Access Control Sync:
```
# Permission sync topics
storage/acl/+/users      # User updates
storage/acl/+/groups     # Group updates
storage/acl/+/rules      # Rule changes

# ACL update format
{
    "type": "user_add",
    "user": "john",
    "groups": ["storage"],
    "permissions": "rw",
    "node": "storage-1"
}
```

### Cluster Management

1. Configuration Sync:
```
# Config sync topics
storage/config/+/services  # Service configs
storage/config/+/network   # Network settings
storage/config/+/security  # Security policies

# Config update format
{
    "service": "nfs",
    "config": {
        "exports": ["/shared"],
        "options": "rw,sync"
    },
    "version": "1.2"
}
```

2. Cluster Operations:
```
# Operation coordination
storage/ops/+/backup     # Backup operations
storage/ops/+/maintain   # Maintenance
storage/ops/+/upgrade    # System upgrades

# Operation message format
{
    "operation": "backup",
    "status": "running",
    "progress": 0.5,
    "node": "storage-1"
}
```

## Network Security

### Encryption

1. ZeroTier Encryption:
```bash
# Enable encryption
zerotier-cli set <network-id> allowDefault=0
zerotier-cli set <network-id> private=1
```

2. Service Encryption:
```ini
# Samba encryption
smb encrypt = required

# MQTT TLS
listener 8883
cafile /etc/mosquitto/ca.crt
certfile /etc/mosquitto/server.crt
keyfile /etc/mosquitto/server.key
```

### Access Control

1. IP Filtering:
```bash
# Allow specific networks
iptables -A INPUT -s 172.16.0.0/16 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

# Drop others
iptables -A INPUT -j DROP
```

2. Service Authentication:
```bash
# NFS security
root_squash,all_squash,secure

# Samba users
smbpasswd -a username

# MQTT authentication
password_file /etc/mosquitto/passwd
allow_anonymous false
```

## Network Monitoring

### Service Monitoring

1. Port Monitoring:
```bash
# Check listening ports
netstat -tulpn

# Monitor connections
watch -n 1 "netstat -an | grep ESTABLISHED"
```

2. Traffic Monitoring:
```bash
# Monitor bandwidth
iftop -i zt+

# Monitor connections
tcpdump -i zt+ port 445
```

### Performance Monitoring

1. Network Statistics:
```bash
# Check interface stats
ip -s link show zt+

# Monitor network load
nload zt+
```

2. Service Statistics:
```bash
# NFS statistics
nfsstat

# Samba statistics
smbstatus --shares
```

## Network Troubleshooting

### Connectivity Issues

1. Network Tests:
```bash
# Test ZeroTier
zerotier-cli listnetworks
ping <zerotier-ip>

# Test services
nc -zv <host> 445
nc -zv <host> 2049
```

2. Service Tests:
```bash
# Test NFS
showmount -e <host>

# Test Samba
smbclient -L <host>

# Test MQTT
mosquitto_sub -h <host> -t test
```

### Performance Issues

1. Network Performance:
```bash
# Test bandwidth
iperf3 -c <host>

# Check latency
mtr <host>
```

2. Service Performance:
```bash
# NFS performance
nfsstat -c

# Samba performance
smbstatus --profiles
```

## Best Practices

### Network Setup

1. Security
   - Enable encryption
   - Use strong authentication
   - Implement firewall rules
   - Regular security audits

2. Performance
   - Optimize MTU settings
   - Configure buffer sizes
   - Monitor bandwidth
   - Load balancing

3. Reliability
   - Redundant paths
   - Automatic failover
   - Service monitoring
   - Regular testing

### Network Maintenance

1. Regular Tasks
   - Update ZeroTier
   - Check connections
   - Monitor performance
   - Review logs

2. Security Updates
   - Update certificates
   - Review access rules
   - Check encryption
   - Audit connections

3. Performance Tuning
   - Adjust buffers
   - Optimize routes
   - Balance load
   - Monitor metrics
