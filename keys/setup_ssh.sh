#!/bin/bash

# Define the SSH configuration file path
SSHD_CONFIG="/etc/ssh/sshd_config"

# Check and update PubkeyAuthentication
if grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG"; then
    echo "PubkeyAuthentication is already set to yes."
else
    echo "Setting PubkeyAuthentication to yes."
    # If it exists, change it; if not, append it
    if grep -q "^#PubkeyAuthentication" "$SSHD_CONFIG"; then
        sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication/' "$SSHD_CONFIG"
    else
        echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
    fi
fi

# Check and update AuthorizedKeysFile
if grep -q "^AuthorizedKeysFile\s*\.ssh/authorized_keys" "$SSHD_CONFIG"; then
    echo "AuthorizedKeysFile is already set correctly."
else
    echo "Setting AuthorizedKeysFile to .ssh/authorized_keys."
    # If it exists, change it; if not, append it
    if grep -q "^#AuthorizedKeysFile" "$SSHD_CONFIG"; then
        sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' "$SSHD_CONFIG"
    else
        echo "AuthorizedKeysFile .ssh/authorized_keys" >> "$SSHD_CONFIG"
    fi
fi

# Restart the SSH service to apply changes
echo "Restarting SSH service..."
systemctl restart ssh

echo "SSH configuration updated successfully."
