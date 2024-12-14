#!/bin/bash

# Check if a destination argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <destination_directory>"
    exit 1
fi

# Set the destination directory from the argument
DESTINATION_DIR="$1"

# Create the destination directory if it does not exist
mkdir -p "$DESTINATION_DIR"

# Generate the SSH key pair
ssh-keygen -t rsa -b 4096 -N "" -f "$DESTINATION_DIR/id_rsa"

# Check if the key generation was successful
if [ $? -eq 0 ]; then
    echo "SSH key pair generated successfully."
    echo "Private key: $DESTINATION_DIR/id_rsa"
    echo "Public key: $DESTINATION_DIR/id_rsa.pub"
else
    echo "Failed to generate SSH key pair."
    exit 1
fi
