#!/usr/bin/env python3
import os
import json
import time
import subprocess
import xml.etree.ElementTree as ET
import paho.mqtt.client as mqtt
import requests
import uuid
import socket

class SyncthingDiscoveryManager:
    def __init__(self):
        # Syncthing configuration
        self.syncthing_config_path = '/etc/syncthing/config.xml'
        self.shared_folder_id = 'common-share'
        
        # ZeroTier configuration
        self.zerotier_network_id = os.environ.get('ZEROTIER_NETWORK_ID', '')
        
        # MQTT Configuration
        self.mqtt_broker = 'localhost'
        self.mqtt_port = 1883
        self.discovery_topic = 'syncthing/discovery'
        self.authorization_topic = 'syncthing/authorize'
        
        # Initialize with retry
        self.initialize_with_retry()

    def initialize_with_retry(self, max_retries=30, delay=10):
        """Initialize components with retry logic"""
        for attempt in range(max_retries):
            try:
                # Wait for MQTT to be ready
                if not self.is_mqtt_ready():
                    raise Exception("MQTT not ready")
                
                # Wait for Syncthing config
                if not os.path.exists(self.syncthing_config_path):
                    raise Exception("Syncthing config not ready")
                
                # Get device ID
                self.device_id = self.get_syncthing_device_id()
                if not self.device_id:
                    raise Exception("Could not get Syncthing device ID")
                
                # Set device name
                self.device_name = f'syncthing-{uuid.uuid4().hex[:8]}'
                
                # Initialize MQTT client
                self.mqtt_client = mqtt.Client(client_id=self.device_name)
                self.mqtt_client.on_connect = self.on_connect
                self.mqtt_client.on_message = self.on_message
                
                print("Successfully initialized all components")
                return
                
            except Exception as e:
                print(f"Initialization attempt {attempt + 1}/{max_retries} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(delay)
                else:
                    raise Exception("Failed to initialize after maximum retries")

    def is_mqtt_ready(self):
        """Check if MQTT broker is ready"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(1)
            result = s.connect_ex(('localhost', 1883))
            s.close()
            return result == 0
        except:
            return False

    def get_syncthing_device_id(self):
        """Extract Syncthing Device ID from configuration"""
        try:
            tree = ET.parse(self.syncthing_config_path)
            device = tree.find('.//device[@name="default"]')
            if device is None:
                device = tree.find('.//device')  # Try any device if default not found
            return device.get('id') if device is not None else None
        except Exception as e:
            print(f"Error extracting device ID: {e}")
            return None

    def get_zerotier_ip(self):
        """Get ZeroTier IP for this device"""
        try:
            # First check if zerotier-one is running
            status = subprocess.run(['zerotier-cli', 'info'], capture_output=True)
            if status.returncode != 0:
                print("ZeroTier not ready")
                return None

            result = subprocess.run(['zerotier-cli', 'info', '-j'],
                                  capture_output=True, text=True)
            zerotier_info = json.loads(result.stdout)
            
            # Get network details
            network_result = subprocess.run(
                ['zerotier-cli', 'network', 'list'],
                capture_output=True, text=True
            )
            
            for line in network_result.stdout.splitlines():
                if self.zerotier_network_id in line:
                    ip_result = subprocess.run(
                        ['zerotier-cli', 'networkinfo', self.zerotier_network_id, '-j'],
                        capture_output=True, text=True
                    )
                    network_info = json.loads(ip_result.stdout)
                    
                    # Extract assigned IP
                    for assign in network_info.get('assignedAddresses', []):
                        if '/' in assign:
                            return assign.split('/')[0]
            
            return None
        except Exception as e:
            print(f"Error getting ZeroTier IP: {e}")
            return None

    def send_device_discovery(self):
        """Broadcast device details via MQTT"""
        zerotier_ip = self.get_zerotier_ip()
        if not zerotier_ip:
            print("No ZeroTier IP available, skipping discovery broadcast")
            return

        discovery_payload = {
            'device_id': self.device_id,
            'device_name': self.device_name,
            'zerotier_ip': zerotier_ip,
            'timestamp': int(time.time())
        }
        
        try:
            self.mqtt_client.publish(
                self.discovery_topic,
                json.dumps(discovery_payload)
            )
        except Exception as e:
            print(f"Error publishing discovery: {e}")

    def authorize_device(self, device_info):
        """Automatically authorize a discovered Syncthing device"""
        try:
            if not device_info.get('zerotier_ip'):
                print("No ZeroTier IP in device info, skipping authorization")
                return

            # Use syncthing CLI or API to add device
            subprocess.run([
                'syncthing',
                '-home=/etc/syncthing',
                '-add-device',
                f'{device_info["device_id"]}={device_info["device_name"]}@{device_info["zerotier_ip"]}:22000'
            ], check=True)
            
            # Add device to shared folder
            subprocess.run([
                'syncthing',
                '-home=/etc/syncthing',
                '-add-folder-device',
                f'{self.shared_folder_id}:{device_info["device_id"]}'
            ], check=True)
            
            # Send authorization confirmation
            self.mqtt_client.publish(
                self.authorization_topic,
                json.dumps({
                    'authorized_device_id': device_info['device_id'],
                    'authorizing_device_id': self.device_id
                })
            )
        except Exception as e:
            print(f"Error authorizing device: {e}")

    def on_connect(self, client, userdata, flags, rc):
        """MQTT connection handler"""
        print("Connected to MQTT broker")
        client.subscribe(self.discovery_topic)
        client.subscribe(self.authorization_topic)
        
        # Broadcast own device details
        self.send_device_discovery()

    def on_message(self, client, userdata, msg):
        """Handle incoming MQTT messages"""
        try:
            payload = json.loads(msg.payload.decode())
            
            # Ignore messages from self
            if payload.get('device_id') == self.device_id:
                return
            
            # Handle discovery messages
            if msg.topic == self.discovery_topic:
                print(f"Discovered new device: {payload}")
                self.authorize_device(payload)
            
            # Optional: Handle authorization confirmations
            elif msg.topic == self.authorization_topic:
                print(f"Authorization message: {payload}")
        except Exception as e:
            print(f"Error processing message: {e}")

    def run(self):
        """Start MQTT client and keep running"""
        while True:
            try:
                print("Attempting to connect to MQTT broker...")
                self.mqtt_client.connect(self.mqtt_broker, self.mqtt_port)
                print("Connected successfully, starting main loop")
                self.mqtt_client.loop_forever()
            except Exception as e:
                print(f"Error in main loop: {e}")
                time.sleep(5)  # Wait before retrying

if __name__ == '__main__':
    while True:
        try:
            manager = SyncthingDiscoveryManager()
            manager.run()
        except Exception as e:
            print(f"Fatal error: {e}")
            time.sleep(10)  # Wait before restarting
