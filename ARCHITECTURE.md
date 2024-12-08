# Storage Node Architecture

[← Back to Index](README.md) | [Design Document](DESIGN.md) | [Configuration Guide →](CONFIGURATION.md)

---

## Table of Contents
- [System Overview](#system-overview)
- [Core Components](#core-components)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [Security Architecture](#security-architecture)
- [Resource Management](#resource-management)
- [Deployment Architecture](#deployment-architecture)
- [Monitoring Architecture](#monitoring-architecture)
- [Backup Architecture](#backup-architecture)
- [Service Integration](#service-integration)
- [Scalability Design](#scalability-design)
- [Future Architecture](#future-architecture)

## System Overview

### Core Components
```
Storage Node
├── File Services
│   ├── NFS Server
│   ├── Samba Server
│   └── Syncthing
├── Network Services
│   ├── ZeroTier
│   └── MQTT Broker
└── Management Services
    ├── Supervisor
    ├── Monitoring
    └── Backup System
```

## Component Architecture

### 1. File Services

#### NFS Server
- Kernel-based NFS v4 server
- Exports configured directories
- UNIX permissions model
- Network-optimized transfers

#### Samba Server
- SMB/CIFS protocol support
- Windows-compatible sharing
- User-based authentication
- File/printer sharing

#### Syncthing
- P2P file synchronization
- Block-level transfers
- Version tracking
- Conflict resolution

### 2. Network Services

#### ZeroTier
- Software-defined networking
- Secure peer connections
- NAT traversal
- Network discovery

#### MQTT Broker
- Message queue system
- Service discovery
- Status updates
- Command distribution

### 3. Management Services

#### Supervisor
- Process management
- Service monitoring
- Auto-restart capability
- Resource control

#### Monitoring
- Resource tracking
- Performance metrics
- Health checks
- Alert system

#### Backup System
- Incremental backups
- Configuration backup
- State preservation
- Recovery tools

## Data Flow

### File Operations
```
Client Request
     │
     ▼
Network Interface
     │
     ▼
Service Router ─────┬─────┬─────┐
     │             │     │     │
     ▼             ▼     ▼     ▼
    NFS          Samba  Sync  MQTT
     │             │     │     │
     └─────┬───────┴─────┴─────┘
           │
           ▼
   Storage Backend
```

### Service Discovery
```
New Node
   │
   ▼
ZeroTier Network
   │
   ▼
MQTT Discovery
   │
   ▼
Service Registration
   │
   ▼
Network Integration
```

## Security Architecture

### Authentication Layers
```
External Request
      │
      ▼
Firewall Rules
      │
      ▼
ZeroTier Auth ───────┐
      │              │
      ▼              ▼
Service Auth    Network Auth
      │              │
      ▼              ▼
Permission Check  Peer Verify
      │              │
      └──────┬───────┘
             ▼
      Resource Access
```

### Data Protection
1. Network Security
   - Encrypted transfers
   - Secure protocols
   - Network isolation
   - Access control

2. Storage Security
   - File permissions
   - Access control
   - Data encryption
   - Secure backups

## Resource Management

### System Resources
```
Hardware Resources
       │
       ▼
Resource Monitor
       │
   ┌───┴────┐
   ▼        ▼
Limits    Alerts
   │        │
   ▼        ▼
Service  Admin
Control  Notice
```

### Storage Resources
```
Storage Pool
    │
    ▼
Allocation
    │
 ┌──┴──┐
 ▼     ▼
Data  Meta
Store  Data
```

## Deployment Architecture

### Container Structure
```
Docker Container
├── Base OS
├── Service Layer
│   ├── NFS
│   ├── Samba
│   └── Syncthing
├── Network Layer
│   ├── ZeroTier
│   └── MQTT
└── Management Layer
    ├── Supervisor
    └── Monitoring
```

### Configuration Management
```
Config Sources
     │
     ▼
Environment Vars
     │
     ▼
Service Configs
     │
  ┌──┴──┐
  ▼     ▼
Static Dynamic
Config Config
```

## Monitoring Architecture

### Metrics Collection
```
Service Metrics
      │
      ▼
Metric Collector
      │
   ┌──┴──┐
   ▼     ▼
Storage  API
      │
      ▼
Dashboard
```

### Alert System
```
Monitoring
    │
    ▼
Thresholds
    │
    ▼
Alert Generator
    │
 ┌──┴──┐
 ▼     ▼
MQTT  Email
Alert Alert
```

## Backup Architecture

### Backup System
```
Data Sources
     │
     ▼
Backup Manager
     │
  ┌──┴──┐
  ▼     ▼
Full  Incremental
     │
     ▼
Storage Backend
```

### Recovery Process
```
Backup Selection
      │
      ▼
Validation Check
      │
      ▼
Service Stop
      │
      ▼
Data Restore
      │
      ▼
Service Start
      │
      ▼
Verification
```

## Service Integration

### Service Communication
```
Service A
   │
   ▼
MQTT Bus ──────┐
   │           │
   ▼           ▼
Service B   Service C
```

### Data Synchronization
```
Local Changes
     │
     ▼
Change Detection
     │
     ▼
Sync Protocol
     │
  ┌──┴──┐
  ▼     ▼
Push   Pull
Updates
```

## Scalability Design

### Horizontal Scaling
```
Node Network
    │
 ┌──┴──┐
 ▼     ▼
Node  Node
 │     │
 └──┬──┘
    ▼
Resource
Sharing
```

### Load Distribution
```
Client Requests
      │
      ▼
Load Balancer
      │
   ┌──┴──┐
   ▼     ▼
Node   Node
```

## Future Architecture

### Planned Enhancements
1. Service Mesh Integration
2. Enhanced Security Layer
3. Advanced Monitoring
4. Automated Scaling
5. Cloud Integration

### Expansion Areas
1. Additional Protocols
2. Enhanced Security
3. Better Performance
4. More Integrations
5. Advanced Analytics
