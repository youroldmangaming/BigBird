# Create the samba config directory
mkdir -p ./config/samba/storage-node-1

# Create a basic smb.conf file
cat > ./config/samba/storage-node-1/smb.conf << 'EOL'
[global]
   workgroup = WORKGROUP
   server string = %h server
   security = user
   map to guest = Bad User
   log file = /var/log/samba/log.%m
   max log size = 50

[public]
   path = /public
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0644
   directory mask = 0755

[shared]
   path = /shared
   browseable = yes
   read only = no
   guest ok = no
   create mask = 0644
   directory mask = 0755
EOL

# Create the samba log directory
mkdir -p ./config/samba/storage-node-1/log

# Set proper permissions
chmod 644 ./config/samba/storage-node-1/smb.conf
