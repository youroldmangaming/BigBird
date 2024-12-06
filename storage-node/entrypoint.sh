#!/bin/bash
set -e

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

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
mkdir -p /var/run/rpcbind /var/lib/nfs/rpc_pipefs /run/sendsigs.omit.d
mkdir -p /var/log/supervisor /var/log/mosquitto /var/log/samba
mkdir -p /home/syncthing/.local /home/syncthing/.config
mkdir -p /var/run/samba
mkdir -p /run/rpcbind
mkdir -p /var/lib/nfs/rpc_pipefs
mkdir -p /var/lib/nfs/v4recovery

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

# Start rpcbind and NFS services
log_msg "Starting rpcbind and NFS services..."
rpcbind || log_msg "Warning: rpcbind failed to start"
exportfs -r || log_msg "Warning: exportfs failed"
/usr/sbin/rpc.nfsd || log_msg "Warning: nfsd failed to start"
/usr/sbin/rpc.mountd --no-udp --debug all || log_msg "Warning: mountd failed to start"

# Initialize rpcbind state
log_msg "Initializing rpcbind state..."
touch /run/rpcbind/rpcbind.xdr
touch /run/rpcbind/portmap.xdr
touch /var/run/rpcbind/rpcbind.lock
chmod 755 /run/rpcbind/rpcbind.xdr
chmod 755 /run/rpcbind/portmap.xdr
chmod 644 /var/run/rpcbind/rpcbind.lock
chown root:root /var/run/rpcbind/rpcbind.lock

# Set up Syncthing configuration
log_msg "Setting up Syncthing configuration..."
if [ ! -f /etc/syncthing/config.xml ]; then
    su - syncthing -s /bin/bash -c "syncthing generate --config=/etc/syncthing"
    sed -i 's/<address>127.0.0.1:8384/<address>0.0.0.0:8384/' /etc/syncthing/config.xml
fi

# Set up Syncthing directories and permissions
log_msg "Setting up Syncthing directories..."
mkdir -p /root/.local /root/.config
chown -R syncthing:syncthing /root/.local /root/.config
chmod 755 /root/.local /root/.config

# Set proper permissions
log_msg "Setting permissions..."
chown -R syncthing:syncthing /etc/syncthing
chown -R syncthing:syncthing /home/syncthing
chown -R syncthing:syncthing /shared /backups /public
chown -R mosquitto:mosquitto /var/log/mosquitto
chmod -R 755 /var/log/supervisor
chown -R rpcbind:rpcbind /var/run/rpcbind /run/rpcbind
chmod -R 755 /var/run/rpcbind /run/rpcbind
chown -R root:root /var/lib/nfs
chmod -R 755 /var/lib/nfs

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

# Start supervisor
log_msg "Starting supervisord..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
