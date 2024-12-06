# Storage Node Backup & Recovery Guide

[← Back to Index](README.md) | [Maintenance Guide](MAINTENANCE.md) | [Monitoring Guide →](MONITORING.md)

---

## Table of Contents
- [Overview](#overview)
- [Quick Reference](#quick-reference)
- [Backup Types](#backup-types)
- [Automated Backup](#automated-backup)
- [Recovery Procedures](#recovery-procedures)
- [Disaster Recovery](#disaster-recovery)
- [Backup Verification](#backup-verification)
- [Monitoring Backups](#monitoring-backups)
- [Best Practices](#best-practices)
- [Recovery Checklist](#recovery-checklist)

## Overview

This guide covers:
- Backup strategies
- Recovery procedures
- Data protection
- Configuration backups
- Disaster recovery

## Quick Reference

```bash
# Quick backup
./manage.sh backup

# Quick restore
./manage.sh restore <backup-file>

# View backup status
./manage.sh backup-status
```

## Backup Types

### 1. Data Backup

#### Shared Directory Backup
```bash
# Full backup
tar czf shared-backup-$(date +%Y%m%d).tar.gz shared/

# Incremental backup
rsync -av --delete shared/ backup-destination/
```

#### Backup Directory Backup
```bash
# Compress backups
tar czf backups-$(date +%Y%m%d).tar.gz backups/

# Encrypted backup
tar czf - backups/ | gpg -c > backups-encrypted.tar.gz.gpg
```

### 2. Configuration Backup

```bash
# Backup all configs
tar czf config-backup.tar.gz \
    .env \
    supervisord.conf \
    exports \
    docker-compose.yml \
    monitor.py \
    setup.sh \
    manage.sh
```

### 3. Service State Backup

```bash
# Syncthing data
tar czf syncthing-data.tar.gz var/lib/syncthing/

# MQTT state
tar czf mqtt-data.tar.gz var/lib/mosquitto/
```

## Automated Backup

### Daily Backup Script

```bash
#!/bin/bash
# backup-daily.sh

BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d)

# Backup shared data
tar czf $BACKUP_DIR/shared-$DATE.tar.gz shared/

# Backup configs
tar czf $BACKUP_DIR/config-$DATE.tar.gz \
    .env \
    supervisord.conf \
    exports \
    docker-compose.yml

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

### Backup Scheduling

```bash
# Add to crontab
0 1 * * * /path/to/backup-daily.sh

# Or use systemd timer
[Unit]
Description=Daily Storage Node Backup

[Timer]
OnCalendar=*-*-* 01:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

## Recovery Procedures

### 1. Data Recovery

```bash
# Restore shared directory
tar xzf shared-backup.tar.gz -C /

# Restore from incremental backup
rsync -av backup-destination/ shared/

# Restore encrypted backup
gpg -d backups-encrypted.tar.gz.gpg | tar xzf -
```

### 2. Configuration Recovery

```bash
# Restore configs
tar xzf config-backup.tar.gz -C /

# Restart services
docker-compose down
docker-compose up -d
```

### 3. Service State Recovery

```bash
# Restore Syncthing
tar xzf syncthing-data.tar.gz -C /var/lib/
chown -R syncthing:syncthing /var/lib/syncthing

# Restore MQTT
tar xzf mqtt-data.tar.gz -C /var/lib/
chown -R mosquitto:mosquitto /var/lib/mosquitto
```

## Disaster Recovery

### Complete System Recovery

1. Install base system:
```bash
# Clone repository
git clone <repository-url>
cd storage-node

# Run setup
./setup.sh
```

2. Restore data:
```bash
# Restore configs
tar xzf config-backup.tar.gz

# Restore data
tar xzf shared-backup.tar.gz
tar xzf backups-backup.tar.gz
```

3. Rebuild and start:
```bash
docker-compose build
docker-compose up -d
```

### Service Recovery

#### NFS Recovery
```bash
# Restore exports
cp backup/exports /etc/exports
exportfs -ra

# Restart NFS
./manage.sh restart-svc nfs
```

#### Samba Recovery
```bash
# Restore config
cp backup/smb.conf /etc/samba/
./manage.sh restart-svc smbd
```

#### Syncthing Recovery
```bash
# Restore config and data
tar xzf syncthing-backup.tar.gz -C /
./manage.sh restart-svc syncthing
```

## Backup Verification

### Data Integrity

```bash
# Verify backup integrity
tar tzf backup-file.tar.gz

# Check file checksums
sha256sum shared-backup.tar.gz > checksums.txt
sha256sum -c checksums.txt
```

### Recovery Testing

```bash
# Test restore in temporary location
mkdir test-restore
tar xzf backup-file.tar.gz -C test-restore/

# Verify permissions
find test-restore -type f -ls
```

## Monitoring Backups

### Backup Status

```bash
# Check last backup
ls -l /path/to/backups/

# Verify backup size
du -sh /path/to/backups/*

# Check backup logs
tail -f /var/log/storage-backup.log
```

### Backup Alerts

Configure in `monitor.py`:
```python
def check_backup_status():
    backup_age = time.time() - os.path.getmtime(BACKUP_PATH)
    if backup_age > 86400:  # 24 hours
        alert("backup_old", f"Backup is {backup_age/3600:.1f} hours old")
```

## Best Practices

### 1. Backup Strategy
- Daily incremental backups
- Weekly full backups
- Monthly configuration backups
- Offsite backup copies

### 2. Security
- Encrypt sensitive backups
- Secure transfer methods
- Regular permission checks
- Access control for backups

### 3. Monitoring
- Backup success/failure alerts
- Storage space monitoring
- Backup integrity checks
- Recovery testing schedule

### 4. Documentation
- Backup procedures
- Recovery steps
- Configuration details
- Emergency contacts

## Recovery Checklist

- [ ] Stop affected services
- [ ] Backup current state
- [ ] Restore from backup
- [ ] Verify permissions
- [ ] Start services
- [ ] Test functionality
- [ ] Monitor for issues
- [ ] Update documentation
