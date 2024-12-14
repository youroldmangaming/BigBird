#!/bin/bash

# Define the SSH configuration file path
SSHD_CONFIG="/etc/ssh/sshd_config"

cp "$SSHD_CONFIG ."

SSHD_CONFIG_LOCAL="./sshd_config"


# Check and update PubkeyAuthentication
if grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG_LOCAL"; then
    echo "PubkeyAuthentication is already set to yes."
else
    echo "Setting PubkeyAuthentication to yes."
    # If it exists, change it; if not, append it
    if grep -q "^#PubkeyAuthentication" "$SSHD_CONFIG_LOCAL"; then
        sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication/' "$SSHD_CONFIG_LOCAL"
    else
        echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG_LOCAL"
    fi
fi

# Check and update AuthorizedKeysFile
if grep -q "^AuthorizedKeysFile\s*\.ssh/authorized_keys" "$SSHD_CONFIG_LOCAL"; then
    echo "AuthorizedKeysFile is already set correctly."
else
    echo "Setting AuthorizedKeysFile to .ssh/authorized_keys."
    # If it exists, change it; if not, append it
    if grep -q "^#AuthorizedKeysFile" "$SSHD_CONFIG_LOCAL"; then
        sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' "$SSHD_CONFIG_LOCAL"
    else
        echo "AuthorizedKeysFile .ssh/authorized_keys" >> "$SSHD_CONFIG_LOCAL"
    fi
fi

# Restart the SSH service to apply changes
#echo "Restarting SSH service..."
#systemctl restart ssh

echo "SSH configuration updated successfully. Localted at $SSHD_CONFIG_LOCAL copy to servers $SSHD_CONFIG to make live"

echo "After copying do a restart \"systemctl restart ssh\""
