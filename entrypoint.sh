#!/bin/bash
set -e

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Run initial setup as root
log_msg "Creating system directories..."
mkdir -p /run/sendsigs.omit.d /run/dbus /var/run/samba
chmod 755 /run/sendsigs.omit.d /run/dbus /var/run/samba

# Clean up any existing ZeroTier processes
log_msg "Cleaning up any existing ZeroTier processes..."
pkill -9 zerotier-one || true
rm -f /var/lib/zerotier-one/*.pid || true
sleep 2

# Stop any existing services
log_msg "Stopping existing services..."
killall -9 rpcbind zerotier-one syncthing 2>/dev/null || true
rm -f /var/run/rpcbind.pid
rm -f /var/run/zerotier-one.pid
rm -f /var/run/syncthing.pid
rm -f /var/run/mosquitto.pid
rm -f /var/run/supervisord.pid

# Clean up any stale files
log_msg "Cleaning up stale files..."
rm -f /run/dbus/pid
rm -f /var/run/rpcbind/rpcbind.pid
rm -f /var/run/samba/smbd.pid
rm -f /var/run/mosquitto.pid
rm -f /var/run/supervisord.pid

# Create necessary directories
log_msg "Creating directories..."
mkdir -p /var/run/rpcbind /var/lib/nfs/rpc_pipefs
mkdir -p /var/log/supervisor /var/log/samba
mkdir -p /home/syncthing/.local /home/syncthing/.config
mkdir -p /run/rpcbind
mkdir -p /var/lib/nfs/rpc_pipefs
mkdir -p /var/lib/nfs/v4recovery

# Set proper permissions
log_msg "Setting permissions..."
chown -R syncthing:syncthing /etc/syncthing
chown -R syncthing:syncthing /home/syncthing
chown -R syncthing:syncthing /shared /backups /public
chmod -R 755 /var/log/supervisor
chown -R rpcbind:rpcbind /var/run/rpcbind /run/rpcbind
chmod -R 755 /var/run/rpcbind /run/rpcbind
chown -R root:root /var/lib/nfs
chmod -R 755 /var/lib/nfs

# Set up NFS exports
log_msg "Configuring NFS exports..."
if [ ! -f /etc/exports ]; then
    echo "/shared *(rw,sync,no_subtree_check,no_root_squash,insecure)" > /etc/exports
    echo "/backups *(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports
    echo "/public *(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports
fi

# Load NFS kernel modules
log_msg "Loading NFS kernel modules..."
modprobe nfs || log_msg "Warning: NFS module not available, continuing anyway..."
modprobe nfsd || log_msg "Warning: NFSD module not available, continuing anyway..."
modprobe nfs_common || log_msg "Warning: NFS common module not available, continuing anyway..."
modprobe rpcsec_gss_krb5 || log_msg "Warning: RPCSEC GSS KRB5 module not available, continuing anyway..."

# Clean up any existing processes
log_msg "Cleaning up any existing processes..."
pkill -9 rpcbind || true
pkill -9 nfsd || true
pkill -9 mountd || true
pkill -9 statd || true

# Start rpcbind and NFS services
log_msg "Starting rpcbind and NFS services..."
rpcbind
rpc.statd
exportfs -r
rpc.nfsd
rpc.mountd --foreground &

# Initialize rpcbind state
log_msg "Initializing rpcbind state..."
mkdir -p /run/rpcbind
touch /run/rpcbind/rpcbind.xdr
touch /run/rpcbind/portmap.xdr

# Set up Syncthing configuration
log_msg "Setting up Syncthing configuration..."
mkdir -p /etc/syncthing
mkdir -p /home/syncthing/.config/syncthing
chown -R syncthing:syncthing /etc/syncthing /home/syncthing
chmod -R 755 /etc/syncthing /home/syncthing

if [ ! -f /etc/syncthing/config.xml ]; then
    # Generate config directly as root first
    syncthing generate --config=/etc/syncthing
    # Then fix permissions
    chown -R syncthing:syncthing /etc/syncthing
    chmod -R 755 /etc/syncthing
    # Modify the configuration to listen on all interfaces
    sed -i 's/<address>127.0.0.1:8384/<address>0.0.0.0:8384/' /etc/syncthing/config.xml
    sed -i 's/<address>default/<address>0.0.0.0:22000/' /etc/syncthing/config.xml
fi

# Ensure syncthing has write access to its directories
chown -R syncthing:syncthing /etc/syncthing /home/syncthing /var/syncthing
chmod -R 755 /etc/syncthing /home/syncthing /var/syncthing

# Initialize ZeroTier
log_msg "Initializing ZeroTier..."
if [ ! -d /var/lib/zerotier-one ]; then
    mkdir -p /var/lib/zerotier-one
    chmod 700 /var/lib/zerotier-one
fi

# Check if port 9993 is available
if netstat -tuln | grep -q ":9993 "; then
    log_msg "ERROR: Port 9993 is already in use"
    netstat -tuln | grep ":9993"
    exit 1
fi



# Store ZeroTier network ID for supervisor to use
if [ -n "$ZEROTIER_NETWORK_ID" ]; then
    log_msg "Storing ZeroTier network ID: $ZEROTIER_NETWORK_ID"
    echo "$ZEROTIER_NETWORK_ID" > /var/lib/zerotier-one/network_id
fi

# Set up MQTT
log_msg "Setting up MQTT..."
mkdir -p /var/run/mosquitto
mkdir -p /var/log/mosquitto
chown -R mosquitto:mosquitto /var/run/mosquitto /etc/mosquitto /var/lib/mosquitto /var/log/mosquitto
chmod -R 755 /var/run/mosquitto /etc/mosquitto /var/lib/mosquitto /var/log/mosquitto

# Start supervisord
log_msg "Starting supervisord..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf


exec python3 /synk/glue.py
