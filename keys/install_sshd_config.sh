#!/bin/bash

# Define the SSH configuration file path
SSHD_CONFIG="/etc/ssh/sshd_config"

cp /etc/ssh/sshd_config .
echo "/etc/ssh/sshd_config ."

cp ./sshd_config ./sshd_config.bak
echo "./sshd_config ./sshd_config.bak"

cp  ./sshd_config.install /etc/ssh/sshd_config
echo "./sshd_config.install /etc/ssh/sshd_config"

echo "SSH configuration updated successfully. Localted at  $SSHD_CONFIG"
echo "After copying do a restarting \"systemctl restart ssh\""

systemctl restart ssh


