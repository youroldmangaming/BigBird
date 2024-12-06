# Storage Node Monitoring Guide

[← Back to Index](README.md) | [Maintenance Guide](MAINTENANCE.md) | [Troubleshooting Guide →](TROUBLESHOOTING.md)

---

## Table of Contents
- [Overview](#overview)
- [Quick Reference](#quick-reference)
- [Service Monitoring](#service-monitoring)
- [Resource Monitoring](#resource-monitoring)
- [Performance Metrics](#performance-metrics)
- [Alert Configuration](#alert-configuration)
- [Log Management](#log-management)
- [Metric Collection](#metric-collection)
- [Dashboard Setup](#dashboard-setup)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This guide covers:
- Service health monitoring
- Resource utilization tracking
- Performance metrics
- Alert configuration
- Log management

## Quick Reference

```bash
# Check all services
./manage.sh status

# View logs
./manage.sh logs

# Monitor resources
./monitor.py --watch
```

## Service Monitoring

### Health Checks

```bash
# Check individual service
./manage.sh status nfs
./manage.sh status smbd
./manage.sh status syncthing

# View service details
supervisorctl status
```

### Service Metrics

#### NFS Metrics
```bash
# Active connections
nfsstat -c

# Server statistics
nfsstat -s

# Mount points
showmount -e localhost
```

#### Samba Metrics
```bash
# Active connections
smbstatus

# Share statistics
smbstatus --shares

# User sessions
smbstatus --processes
```

#### Syncthing Metrics
```bash
# API endpoint: http://localhost:8384/rest/system/status
curl -X GET http://localhost:8384/rest/system/status

# Sync status
curl -X GET http://localhost:8384/rest/db/status
```

## Resource Monitoring

### System Resources

```bash
# CPU and Memory
top -b -n 1

# Disk Usage
df -h
du -sh /shared/* /backups/*

# Network Usage
iftop -i eth0
```

### Docker Resources

```bash
# Container stats
docker stats storage-node

# Resource limits
docker inspect storage-node
```

## Performance Metrics

### Storage Performance

```bash
# Disk I/O
iostat -x 1

# File system latency
ioping /shared

# Write speed test
dd if=/dev/zero of=/shared/test bs=1M count=1000
```

### Network Performance

```bash
# Network throughput
iperf3 -s  # Server
iperf3 -c <server-ip>  # Client

# Connection tracking
netstat -an | grep :445
```

## Alert Configuration

### System Alerts

```python
# monitor.py
def check_disk_space():
    """Monitor disk space and alert if usage exceeds threshold"""
    usage = psutil.disk_usage('/shared')
    if usage.percent > 90:
        alert('disk_full', f'Disk usage at {usage.percent}%')

def check_memory():
    """Monitor memory usage and alert if exceeds threshold"""
    memory = psutil.virtual_memory()
    if memory.percent > 90:
        alert('high_memory', f'Memory usage at {memory.percent}%')
```

### Service Alerts

```python
def check_service_health():
    """Monitor service health and alert on failures"""
    services = ['nfs', 'smbd', 'syncthing']
    for service in services:
        status = get_service_status(service)
        if status != 'running':
            alert('service_down', f'{service} is {status}')
```

### Alert Channels

```python
def alert(alert_type, message):
    """Send alerts through configured channels"""
    # MQTT Alert
    mqtt_client.publish(f'storage/alerts/{alert_type}', message)
    
    # Log Alert
    logging.warning(f'ALERT: {alert_type} - {message}')
    
    # Email Alert (if configured)
    if EMAIL_ALERTS_ENABLED:
        send_email_alert(alert_type, message)
```

## Log Management

### Log Collection

```bash
# View all logs
./manage.sh logs

# Service specific logs
./manage.sh logs nfs
./manage.sh logs smbd
./manage.sh logs syncthing

# System logs
journalctl -u storage-node
```

### Log Rotation

```conf
# /etc/logrotate.d/storage-node
/var/log/storage-node/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
```

### Log Analysis

```bash
# Search logs
grep "error" /var/log/storage-node/*.log

# Count errors by type
awk '/error/ {print $4}' /var/log/storage-node/service.log | sort | uniq -c

# View recent errors
tail -f /var/log/storage-node/service.log | grep -i error
```

## Metric Collection

### Prometheus Integration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'storage-node'
    static_configs:
      - targets: ['localhost:9100']
    metrics_path: '/metrics'
```

### Custom Metrics

```python
# metrics.py
from prometheus_client import Counter, Gauge

# Define metrics
FILE_OPERATIONS = Counter('storage_file_operations_total',
                         'Number of file operations',
                         ['operation'])

STORAGE_USAGE = Gauge('storage_usage_bytes',
                     'Storage space usage in bytes',
                     ['volume'])

# Update metrics
def track_operation(operation):
    FILE_OPERATIONS.labels(operation=operation).inc()

def update_storage_usage():
    usage = psutil.disk_usage('/shared')
    STORAGE_USAGE.labels(volume='shared').set(usage.used)
```

## Dashboard Setup

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Storage Node Metrics",
    "panels": [
      {
        "title": "Disk Usage",
        "type": "gauge",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "storage_usage_bytes{volume='shared'}"
          }
        ]
      },
      {
        "title": "File Operations",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(storage_file_operations_total[5m])"
          }
        ]
      }
    ]
  }
}
```

## Performance Tuning

### Monitoring for Optimization

```bash
# I/O wait time
iostat -x 1

# File system cache
free -m
vmstat 1

# Network buffer usage
netstat -s
```

### Benchmark Tools

```bash
# Disk performance
fio --name=test --rw=randwrite --size=1G

# Network performance
iperf3 -c localhost -p 445

# File system performance
bonnie++ -d /shared -u root
```

## Troubleshooting

### Common Issues

1. High Resource Usage
```bash
# Check top processes
top -o %CPU
top -o %MEM

# I/O bottlenecks
iotop
```

2. Network Issues
```bash
# Check connections
netstat -tupn

# Network errors
netstat -s | grep -i error
```

3. Service Issues
```bash
# Check service logs
./manage.sh logs <service>

# Service status
supervisorctl status
```

### Debug Mode

```bash
# Enable debug logging
export DEBUG=1
./monitor.py --debug

# Verbose service output
supervisorctl start <service> -l debug
```

## Best Practices

1. Regular Monitoring
   - Check service health daily
   - Monitor resource usage trends
   - Review logs for errors
   - Test backup integrity

2. Alert Configuration
   - Set appropriate thresholds
   - Configure multiple alert channels
   - Document alert responses
   - Test alert system regularly

3. Log Management
   - Implement log rotation
   - Archive old logs
   - Monitor log volume
   - Regular log analysis

4. Performance Tracking
   - Baseline performance metrics
   - Track trends over time
   - Document optimization changes
   - Regular benchmarking
