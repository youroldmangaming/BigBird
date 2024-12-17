#!/bin/bash

# Check if a destination argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <account>"
    exit 1
fi

# Set the account and destination directory
ACCOUNT="$1"
DESTINATION_DIR="./.ssh"  # Current directory
KEY_FILE="$DESTINATION_DIR/id_rsa"

# Copy the public key to the authorized_keys on the localhost
ssh-copy-id -i "./keys/.ssh/id_rsa.pub" "$ACCOUNT@localhost"
cp ./keys/.ssh/id_rsa.pub /root/.ssh/authorized_keys

cp /etc/ssh/sshd_config ./keys/sshd_config.bak
cp ./keys/sshd_config.install /etc/ssh/sshd_config

systemctl restart ssh
