#!/usr/bin/env python3
import os
import subprocess
import json
import logging
import time
import socket




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
        self.network_id = os.getenv('NETWORK_ID', '17d709436c9787ee')
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
        try:
            # Get network members
            result = subprocess.run(
                ['zerotier-cli', 'listnetworks', '-j'],
                capture_output=True,
                text=True,
                check=True
            )
            
            networks = json.loads(result.stdout)
            
            # Find the specific network
            target_network = next(
                (net for net in networks if net['id'] == self.network_id), 
                None
            )
            
            if not target_network:
                logging.warning(f"Network {self.network_id} not found")
                return []
            
            # Extract network members
            network_members = [
                {
                    'hostname': ip.split('/')[0],
                    'remote_path': self.shared_directory
                }
                for ip in target_network.get('assignedAddresses', [])
                if ip.startswith('192.168.192.')
            ]
            
            return network_members
        
        except Exception as e:
            logging.error(f"Error retrieving network members: {e}")
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
            
            # Add only if not already in config
            if member['hostname'] not in existing_hostnames:
                config['nodes'].append({
                    'hostname': member['hostname'],
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
