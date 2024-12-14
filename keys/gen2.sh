#!/bin/bash

# Check if a destination argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <account>"
    exit 1
fi

# Set the account and destination directory
ACCOUNT="$1"
DESTINATION_DIR="."  # Current directory
KEY_FILE="$DESTINATION_DIR/id_rsa"

# Generate the SSH key pair
ssh-keygen -t rsa -b 4096 -N "" -f "$KEY_FILE"

# Check if the key generation was successful
if [ $? -eq 0 ]; then
    echo "SSH key pair generated successfully."
    echo "Private key: $KEY_FILE"
    echo "Public key: ${KEY_FILE}.pub"

    # Copy the public key to the authorized_keys on the localhost
    ssh-copy-id -i "${KEY_FILE}.pub" "$ACCOUNT@localhost"
    ssh-copy-id -i "${KEY_FILE}.pub"  "root@localhost"
else
    echo "Failed to generate SSH key pair."
    exit 1
fi

