# Storage Node Troubleshooting Guide

[← Back to Index](README.md) | [Monitoring Guide](MONITORING.md) | [Development Guide →](DEVELOPMENT.md)

---

## Table of Contents
- [Quick Diagnostic Commands](#quick-diagnostic-commands)
- [Common Issues and Solutions](#common-issues-and-solutions)
- [Advanced Troubleshooting](#advanced-troubleshooting)
- [Recovery Procedures](#recovery-procedures)
- [Monitoring Tools](#monitoring-tools)
- [Getting Help](#getting-help)

## Quick Diagnostic Commands

```bash
# Check overall status
./manage.sh status

# View all service logs
./manage.sh logs

# Check disk space
./manage.sh disk

# Verify network connectivity
./manage.sh network
```

## Common Issues and Solutions

### 1. Container Won't Start

**Symptoms:**
- Container exits immediately
- Services fail to initialize

**Solutions:**
1. Check logs:
```bash
docker-compose logs
```

2. Verify directory permissions:
```bash
ls -la shared backups public
chmod -R 777 shared backups public
```

3. Check port conflicts:
```bash
netstat -tulpn | grep -E '445|2049|22000|1883|9993'
```

### 2. NFS Issues

**Symptoms:**
- NFS mounts fail
- "Connection refused" errors

**Solutions:**
1. Check NFS service status:
```bash
./manage.sh logs nfs
./manage.sh logs rpcbind
```

2. Verify exports:
```bash
docker exec storage-node exportfs -v
```

3. Test NFS connectivity:
```bash
# On client
showmount -e <host-ip>
rpcinfo -p <host-ip>
```

4. Common mount fixes:
```bash
# Linux/macOS
mount -t nfs -o vers=4,resvport <host-ip>:/shared /mnt/shared

# Force unmount if stuck
umount -f /mnt/shared
```

### 3. Samba Access Problems

**Symptoms:**
- Cannot connect to shares
- Permission denied errors

**Solutions:**
1. Check Samba status:
```bash
./manage.sh logs smbd
```

2. Test connectivity:
```bash
smbclient -L //<host-ip> -N
```

3. Verify permissions:
```bash
docker exec storage-node smbstatus
```

### 4. Syncthing Sync Issues

**Symptoms:**
- Files not syncing
- Devices not connecting

**Solutions:**
1. Check Syncthing status:
```bash
./manage.sh logs syncthing
```

2. Verify web interface access:
```bash
curl -I http://<host-ip>:22000
```

3. Reset Syncthing:
```bash
./manage.sh restart-svc syncthing
```

### 5. ZeroTier Network Problems

**Symptoms:**
- No network connectivity
- Peers not visible

**Solutions:**
1. Check ZeroTier status:
```bash
docker exec storage-node zerotier-cli status
```

2. Verify network membership:
```bash
docker exec storage-node zerotier-cli listnetworks
```

3. Rejoin network:
```bash
docker exec storage-node zerotier-cli leave $ZEROTIER_NETWORK_ID
docker exec storage-node zerotier-cli join $ZEROTIER_NETWORK_ID
```

### 6. Resource Issues

**Symptoms:**
- Services becoming unresponsive
- Container crashes

**Solutions:**
1. Check resource usage:
```bash
docker stats storage-node
```

2. Monitor system resources:
```bash
./manage.sh status
```

3. Clear logs if they're too large:
```bash
docker exec storage-node supervisorctl clear all
```

### 7. Permission Problems

**Symptoms:**
- Cannot write to shared directories
- Access denied errors

**Solutions:**
1. Reset permissions:
```bash
chmod -R 777 shared backups public
chown -R nobody:nogroup shared backups public
```

2. Check effective permissions:
```bash
docker exec storage-node ls -la /shared
docker exec storage-node id
```

## Advanced Troubleshooting

### Service Logs

Access detailed logs for each service:

```bash
# NFS server logs
./manage.sh logs nfs

# Samba logs
./manage.sh logs smbd

# Syncthing logs
./manage.sh logs syncthing

# ZeroTier logs
./manage.sh logs zerotier

# MQTT logs
./manage.sh logs mosquitto
```

### Network Diagnostics

1. Check all listening ports:
```bash
docker exec storage-node netstat -tulpn
```

2. Test network connectivity:
```bash
# NFS
nc -zv <host-ip> 2049

# Samba
nc -zv <host-ip> 445

# Syncthing
nc -zv <host-ip> 22000

# MQTT
nc -zv <host-ip> 1883
```

### Container Inspection

1. View container details:
```bash
docker inspect storage-node
```

2. Check mounted volumes:
```bash
docker inspect -f '{{ range .Mounts }}{{ .Source }} -> {{ .Destination }}{{ println }}{{ end }}' storage-node
```

### System Logs

1. View Docker logs:
```bash
docker logs storage-node
```

2. Check system journal:
```bash
journalctl -u docker.service
```

## Recovery Procedures

### 1. Service Recovery

```bash
# Restart individual service
./manage.sh restart-svc <service-name>

# Restart all services
./manage.sh restart

# Reset service to default state
docker-compose down
docker-compose up -d
```

### 2. Data Recovery

```bash
# Backup configuration
tar -czf config-backup.tar.gz .env supervisord.conf

# Restore configuration
tar -xzf config-backup.tar.gz
```

### 3. Clean Start

```bash
# Stop container
docker-compose down

# Remove container and volumes
docker-compose down -v

# Rebuild and start
docker-compose build
docker-compose up -d
```

## Monitoring Tools

### 1. Service Health Checks

```bash
# Start monitoring
docker exec storage-node python3 /usr/local/bin/monitor.py

# View monitoring logs
tail -f var/log/storage-monitor.log
```

### 2. Resource Monitoring

```bash
# Container stats
docker stats storage-node

# Disk usage
./manage.sh disk

# Network connections
./manage.sh network
```

## Getting Help

If you're still experiencing issues:

1. Collect diagnostic information:
```bash
./manage.sh status > status.log
./manage.sh logs > service.log
./manage.sh network > network.log
```

2. Check for known issues in the documentation

3. Submit an issue with:
   - Error messages
   - Log outputs
   - Steps to reproduce
   - System information
