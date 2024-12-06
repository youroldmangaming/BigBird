# Storage Node Command Reference

## Quick Reference

| Category | Command | Description |
|----------|---------|-------------|
| Services | `start` | Start all services |
| | `stop` | Stop all services |
| | `restart` | Restart all services |
| | `status` | Check service status |
| Network | `network-test` | Test network connectivity |
| | `list-peers` | List connected peers |
| | `join-network` | Join ZeroTier network |
| Storage | `disk-usage` | Check storage usage |
| | `backup` | Create backup |
| | `restore` | Restore from backup |

## Service Management

### Basic Operations
```bash
# Start/Stop/Restart
./manage.sh start [service]        # Start services
./manage.sh stop [service]         # Stop services
./manage.sh restart [service]      # Restart services
./manage.sh reload [service]       # Reload configuration

# Status
./manage.sh status [service]       # Check status
./manage.sh health                 # Check health
./manage.sh info [service]         # Service information
```

### Service Configuration
```bash
# Configuration
./manage.sh configure [service]    # Configure service
./manage.sh show-config [service]  # Show configuration
./manage.sh reset-config [service] # Reset to defaults
./manage.sh verify-config         # Verify configuration

# Updates
./manage.sh update [service]      # Update service
./manage.sh rollback [service]    # Rollback update
./manage.sh version [service]     # Show version
```

## Network Management

### Network Operations
```bash
# ZeroTier
./manage.sh join-network          # Join network
./manage.sh leave-network         # Leave network
./manage.sh network-status        # Network status
./manage.sh list-peers           # List peers

# Connectivity
./manage.sh network-test         # Test connectivity
./manage.sh speed-test          # Test bandwidth
./manage.sh ping [host]         # Ping host
./manage.sh trace [host]        # Trace route
```

### Network Configuration
```bash
# Setup
./manage.sh setup-network        # Configure network
./manage.sh reset-network        # Reset network
./manage.sh update-network       # Update settings

# Security
./manage.sh setup-firewall      # Configure firewall
./manage.sh allow-port [port]   # Allow port
./manage.sh deny-port [port]    # Deny port
```

## Storage Management

### Storage Operations
```bash
# Space Management
./manage.sh disk-usage          # Check usage
./manage.sh clean-temp          # Clean temp files
./manage.sh optimize-storage    # Optimize storage

# Permissions
./manage.sh fix-permissions     # Fix permissions
./manage.sh check-permissions   # Check permissions
./manage.sh set-acl [path]     # Set ACL
```

### Backup Operations
```bash
# Backup
./manage.sh backup             # Create backup
./manage.sh backup-full        # Full backup
./manage.sh backup-incremental # Incremental backup
./manage.sh verify-backup      # Verify backup

# Restore
./manage.sh restore [backup]   # Restore backup
./manage.sh list-backups      # List backups
./manage.sh clean-backups     # Clean old backups
```

## Security Management

### Access Control
```bash
# User Management
./manage.sh add-user [user]    # Add user
./manage.sh remove-user [user] # Remove user
./manage.sh list-users        # List users
./manage.sh reset-password    # Reset password

# Permissions
./manage.sh grant [user] [perm] # Grant permission
./manage.sh revoke [user] [perm] # Revoke permission
./manage.sh show-perms [user]   # Show permissions
```

### Security Operations
```bash
# Security
./manage.sh security-check     # Security audit
./manage.sh update-certs      # Update certificates
./manage.sh rotate-keys       # Rotate keys
./manage.sh encrypt-data      # Encrypt data
```

## Monitoring Commands

### System Monitoring
```bash
# Resource Monitoring
./manage.sh monitor           # Monitor system
./manage.sh top              # Show top processes
./manage.sh ps               # List processes
./manage.sh resources        # Show resources

# Metrics
./manage.sh metrics          # Show metrics
./manage.sh stats           # Show statistics
./manage.sh performance     # Performance data
```

### Log Management
```bash
# Logs
./manage.sh logs [service]   # View logs
./manage.sh error-logs      # View errors
./manage.sh audit-logs      # View audit logs
./manage.sh clean-logs      # Clean old logs

# Reports
./manage.sh report          # Generate report
./manage.sh export-logs     # Export logs
./manage.sh analyze-logs    # Analyze logs
```

## Maintenance Commands

### System Maintenance
```bash
# Updates
./manage.sh update-system    # Update system
./manage.sh upgrade         # Upgrade services
./manage.sh patch          # Apply patches

# Cleanup
./manage.sh clean          # Clean system
./manage.sh prune         # Prune old data
./manage.sh optimize      # Optimize system
```

### Service Maintenance
```bash
# Service Tasks
./manage.sh repair [service] # Repair service
./manage.sh verify [service] # Verify service
./manage.sh reset [service]  # Reset service
./manage.sh tune [service]   # Tune service
```

## Troubleshooting Commands

### Diagnostic Tools
```bash
# Diagnostics
./manage.sh diagnose        # Run diagnostics
./manage.sh check-health    # Health check
./manage.sh test-services   # Test services
./manage.sh verify-system   # System check

# Debug
./manage.sh debug [service] # Debug service
./manage.sh trace [service] # Trace service
./manage.sh dump [service]  # Dump state
```

### Recovery Tools
```bash
# Recovery
./manage.sh recover        # System recovery
./manage.sh emergency     # Emergency mode
./manage.sh safe-mode    # Safe mode
./manage.sh rollback     # Rollback changes
```

## Configuration Commands

### System Configuration
```bash
# Settings
./manage.sh set [key] [value] # Set setting
./manage.sh get [key]        # Get setting
./manage.sh list-settings   # List settings
./manage.sh reset-settings  # Reset settings

# Environment
./manage.sh env            # Show environment
./manage.sh set-env       # Set environment
./manage.sh reset-env     # Reset environment
```

### Service Configuration
```bash
# Service Settings
./manage.sh service-config [service] # Configure service
./manage.sh tune-service [service]   # Tune service
./manage.sh optimize-service [service] # Optimize service
```

## Advanced Commands

### Development Tools
```bash
# Development
./manage.sh dev-mode      # Development mode
./manage.sh test         # Run tests
./manage.sh benchmark    # Run benchmarks
./manage.sh profile     # Profile system

# Debug
./manage.sh debug-mode  # Debug mode
./manage.sh trace-all  # Trace all
./manage.sh core-dump # Generate core dump
```

### System Tools
```bash
# System
./manage.sh system-info  # System information
./manage.sh hardware    # Hardware info
./manage.sh drivers    # Driver info
./manage.sh modules   # Module info
```
