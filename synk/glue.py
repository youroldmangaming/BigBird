import os
import subprocess
import json
import logging
import time
import socket
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

class DynamicNodeConfigManager:
    def __init__(
        self,
        config_path='multi_node_sync.json',
        shared_directory='/shared'
    ):
        self.config_path = config_path
        self.shared_directory = shared_directory
        self.local_hostname = socket.gethostname()
        self.network_id = os.getenv('NETWORK_ID', '1d71939404640f20')
        self.api_token = '8dZCe3xyG4FBqp9uFir7nfx9yFP7i2jx'
        self.sync_interval = int(os.getenv('SYNC_INTERVAL', '300'))

        # Ensure config file exists
        self.initialize_config_file()

    def initialize_config_file(self):
        """Create initial configuration file if it doesn't exist"""
        if not os.path.exists(self.config_path):
            initial_config = {
                "shared_directory": self.shared_directory,
                "nodes": []
            }
            self.save_config(initial_config)

    def load_config(self):
        """Load configuration from JSON file"""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            logging.error(f"Error loading config: {e}")
            return {
                "shared_directory": self.shared_directory,
                "nodes": []
            }

    def save_config(self, config):
        """Save configuration to JSON file"""
        try:
            with open(self.config_path, 'w') as f:
                json.dump(config, f, indent=4)
            logging.info(f"Updated configuration saved to {self.config_path}")
        except Exception as e:
            logging.error(f"Error saving config: {e}")

    def get_zerotier_network_members(self):
        """Retrieve ZeroTier network members"""
        url = f"https://api.zerotier.com/api/v1/network/{self.network_id}/member"
        headers = {
            "Authorization": f"token {self.api_token}"  # Corrected formatting
        }

        print(url)
        print(headers)

        # Make the API request
        response = requests.get(url, headers=headers)

        # Check if the request was successful
        if response.status_code == 200:
            members = response.json()
            print(members)

            network_members = []  # Initialize the list outside the loop

            # Extract and print the desired information
            for member in members:
                member_id = member.get("id")
                last_seen = member.get("lastSeen")
                physical_address = member.get("physicalAddress")
                self.zerotier_ip = member.get("config", {}).get("ipAssignments", [None])[0]  # Safely get the first IP if available
                self.name = member.get("name")

                # Print the results
                print(f"Member ID: {member_id}")
                print(f"Last Seen: {last_seen}")
                print(f"Physical Address: {physical_address}")
                print(f"ZeroTier IP Address: {self.zerotier_ip}")
                print()  # Blank line for readability

                # Append the member's details to the network_members list
                network_members.append({
                    'hostname': self.name,
                    'ip': self.zerotier_ip,
                    'remote_path': self.shared_directory
                })

            return network_members

        else:
            print(f"Failed to retrieve data: {response.status_code} - {response.text}")
            return []





    def update_config(self):
        """Dynamically update configuration with new network members"""
        # Load existing configuration
        config = self.load_config()

        # Get current network members
        network_members = self.get_zerotier_network_members()

        # Track changes
        config_updated = False

        # Add new members to configuration
        existing_hostnames = {node['hostname'] for node in config.get('nodes', [])}

        for member in network_members:
            # Skip local host
            if member['hostname'] == self.local_hostname:
                continue

            #rsync -avz --progress -e "ssh" ../shared/ rpi@192.168.192.58:/home/rpi/shared/
            # Add only if not already in config
            if member['hostname'] not in existing_hostnames:
                config['nodes'].append({
                    'hostname': member['hostname'],
                    'ip': member['ip'],                
                    'remote_path': member['remote_path']
                })
                logging.info(f"Added new node: {member['hostname']}")
                config_updated = True

        # Save updated configuration if changes were made
        if config_updated:
            self.save_config(config)

    def run(self):
        """Continuously monitor and update network configuration"""
        while True:
            try:
                self.update_config()
                time.sleep(self.sync_interval)
            except Exception as e:
                logging.error(f"Error in monitoring loop: {e}")
                time.sleep(self.sync_interval)

def main():
    try:
        config_manager = DynamicNodeConfigManager()
        config_manager.run()
    except Exception as e:
        logging.error(f"Initialization failed: {e}")

if __name__ == "__main__":
    main()




