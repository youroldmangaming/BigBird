#!/bin/bash

# Path to the JSON file
JSON_FILE="multi_node_sync.json"
# Path to the output hosts file
ZT_HOSTS_FILE="./hosts.zt"
HOSTS_FILE="/etc/hosts"
HOSTS_BAK="./hosts.bak"

# Function to update the local hosts file
update_hosts() {
    cp /etc/hosts ./hosts.bak
    touch "$ZT_HOSTS_FILE"

 
    # Clear the existing entries for the specified nodes in the ZT_HOSTS_FILE
    sed -i '/^# BEGIN ZEROTIER NODES/,/^# END ZEROTIER NODES/d' "$ZT_HOSTS_FILE"
    sed -i '/^# BEGIN ZEROTIER NODES/,/^# END ZEROTIER NODES/d' ./hosts.bak

    # Add new entries for the nodes
    echo "# BEGIN ZEROTIER NODES" >> "$ZT_HOSTS_FILE"
    
    # Read the JSON file and extract hostname and IP
    jq -c '.nodes[]' "$JSON_FILE" | while IFS= read -r node; do
        HOSTNAME=$(echo "$node" | jq -r '.hostname')
        IP=$(echo "$node" | jq -r '.ip')
        echo "$IP $HOSTNAMEz" >> "$ZT_HOSTS_FILE"
    done

    echo "# END ZEROTIER NODES" >> "$ZT_HOSTS_FILE"


    # Append the new entries from the ZT_HOSTS_FILE to /etc/hosts
    cat "$ZT_HOSTS_FILE" >> ./hosts.bak
    cp ./hosts.bak /etc/hosts
}

# Set the frequency (in seconds) for reading the JSON file
FREQUENCY=60*60  # Change this value as needed

# Infinite loop to update hosts file at set frequency
while true; do
    update_hosts
    sleep "$FREQUENCY"
done
