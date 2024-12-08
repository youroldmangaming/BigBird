# Storage Node Design Document

[← Back to Index](README.md) | [Architecture Guide](ARCHITECTURE.md) | [Development Guide →](DEVELOPMENT.md)

---

## Table of Contents
- [System Architecture](#system-architecture)
- [Core Components](#core-components)
- [System Design](#system-design)
- [Security Architecture](#security-architecture)
- [Initialization Flow](#initialization-flow)
- [Platform Considerations](#platform-considerations)
- [Error Handling](#error-handling)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Future Enhancements](#future-enhancements)
- [Implementation Notes](#implementation-notes)

## System Architecture

### Overview
The storage node is a containerized solution that provides multiple network storage and synchronization services in a single, manageable unit. It is designed to be platform-independent while providing graceful degradation of features based on host system capabilities.

### Core Components

#### 1. Base System
- **Operating System**: Ubuntu Latest (ARM64)
- **Container Runtime**: Docker
- **Process Management**: Supervisord
- **System Requirements**:
  * CPU: ARM64 compatible
  * Memory: 512MB minimum
  * Storage: Based on usage requirements

#### 2. Service Layer

##### File Sharing Services
1. **NFS Server**
   - Version: NFSv4 only
   - Configuration: `/etc/exports`
   - Mount Points:
     * `/shared`: Primary storage
     * `/backups`: Backup storage
     * `/public`: Public access
   - Export Options:
     * `rw,sync,no_subtree_check,no_root_squash,insecure`
     * Unique `fsid` for each export

2. **Samba Server**
   - Protocol: SMB3
   - Share Configuration: Anonymous access
   - Integration: Shares aligned with NFS exports

3. **Syncthing**
   - Mode: P2P synchronization
   - Web Interface: Port 8384
   - Sync Protocol: Port 22000
   - Discovery: Global + Local

##### Network Services
1. **ZeroTier**
   - Purpose: Software-defined networking
   - Configuration: Network ID based
   - Port: 9993/UDP

2. **MQTT Broker**
   - Purpose: Service discovery and messaging
   - Port: 1883
   - Topics:
     * `storage/discovery`
     * `storage/status`
     * `storage/control`

### System Design

#### Process Management
```
supervisord
├── zerotier
├── syncthing
├── rpcbind
├── nfs
├── mountd
├── smbd
├── nmbd
├── mqtt
└── discovery
```

#### Directory Structure
```
/
├── shared/           # Primary storage
│   └── .stfolder    # Syncthing marker
├── backups/         # Backup storage
├── public/          # Public access
└── var/
    ├── log/         # Service logs
    │   ├── supervisor/
    │   ├── syncthing/
    │   └── samba/
    ├── run/         # Runtime files
    └── lib/
        ├── nfs/     # NFS state
        └── zerotier/ # ZeroTier config
```

### Security Architecture

#### File Permissions
1. **Shared Directories**
   ```
   drwxrwxrwx shared   (777)
   drwxrwxrwx backups  (777)
   drwxrwxrwx public   (777)
   ```

2. **Service Directories**
   ```
   drwxr-xr-x var/log  (755)
   drwxr-xr-x var/run  (755)
   ```

#### Network Security
1. **Port Exposure**
   - Required ports only
   - Host network mode for full functionality
   - ZeroTier for secure remote access

2. **Service Authentication**
   - Syncthing: Device ID based
   - NFS: IP/network based
   - Samba: Anonymous (configurable)

### Initialization Flow

1. **Container Startup**
   ```
   entrypoint.sh
   ├── Clean existing processes
   ├── Create directories
   ├── Initialize rpcbind state
   ├── Configure NFS exports
   ├── Setup Syncthing
   ├── Set permissions
   ├── Initialize ZeroTier
   └── Start supervisord
   ```

2. **Service Startup Order**
   1. rpcbind (priority 10)
   2. nfs (priority 20)
   3. mountd (priority 30)
   4. Other services (priority 40+)

### Platform Considerations

#### Linux Hosts
- Full functionality
- Native kernel module support
- Maximum performance

#### macOS/Docker Desktop
- Limited NFS functionality
- LinuxKit kernel constraints
- Alternative sharing methods recommended

#### Windows/Docker Desktop
- Similar limitations to macOS
- Use Samba as primary protocol

### Error Handling

1. **Service Failures**
   - Automatic restart with backoff
   - Logging to specified files
   - Status reporting via MQTT

2. **Resource Exhaustion**
   - Service prioritization
   - Graceful degradation
   - Alert via logs/MQTT

### Monitoring and Maintenance

1. **Health Checks**
   - Service status via supervisord
   - Network connectivity tests
   - Storage space monitoring

2. **Logging**
   - Centralized in `/var/log`
   - Rotation policy
   - Level-based filtering

### Future Enhancements

1. **Short Term**
   - Enhanced permission management
   - Service health monitoring
   - Configuration templating

2. **Long Term**
   - Multi-node clustering
   - Automated failover
   - Advanced monitoring

## Implementation Notes

### Critical Paths
1. Service initialization order
2. Permission management
3. Network configuration
4. Storage management

### Known Limitations
1. NFS kernel module dependency
2. Platform-specific constraints
3. Resource consumption

### Best Practices
1. Regular backup of configuration
2. Monitoring of logs
3. Security updates
4. Resource monitoring
