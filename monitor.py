#!/usr/bin/env python3

import os
import sys
import time
import subprocess
import logging
import paho.mqtt.client as mqtt
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/storage-monitor.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

class StorageMonitor:
    def __init__(self):
        self.services = [
            "rpcbind",
            "nfs",
            "mountd",
            "smbd",
            "syncthing",
            "zerotier-one",
            "mosquitto"
        ]
        self.mqtt_client = mqtt.Client()
        self.setup_mqtt()

    def setup_mqtt(self):
        """Configure MQTT client and connect to broker"""
        try:
            self.mqtt_client.connect("localhost", 1883, 60)
            self.mqtt_client.loop_start()
            logging.info("Connected to MQTT broker")
        except Exception as e:
            logging.error(f"Failed to connect to MQTT broker: {e}")

    def check_service_status(self):
        """Check status of all monitored services"""
        status = {}
        for service in self.services:
            try:
                result = subprocess.run(
                    ["supervisorctl", "status", service],
                    capture_output=True,
                    text=True
                )
                is_running = "RUNNING" in result.stdout
                status[service] = "running" if is_running else "stopped"
                
                # Publish status to MQTT
                self.mqtt_client.publish(
                    f"storage/status/{service}",
                    "online" if is_running else "offline"
                )
                
                if not is_running:
                    logging.warning(f"Service {service} is not running")
            except Exception as e:
                logging.error(f"Error checking {service}: {e}")
                status[service] = "error"
        return status

    def check_disk_space(self):
        """Monitor disk space usage"""
        paths = ["/shared", "/backups", "/public"]
        usage = {}
        
        for path in paths:
            try:
                result = subprocess.run(
                    ["df", "-h", path],
                    capture_output=True,
                    text=True
                )
                usage[path] = result.stdout.split("\n")[1].split()[4]
                
                # Alert if usage is over 90%
                if int(usage[path].rstrip("%")) > 90:
                    logging.warning(f"High disk usage on {path}: {usage[path]}")
                    self.mqtt_client.publish(
                        "storage/alerts/disk",
                        f"High usage on {path}: {usage[path]}"
                    )
            except Exception as e:
                logging.error(f"Error checking disk space for {path}: {e}")
        return usage

    def check_network_connectivity(self):
        """Verify network services are accessible"""
        ports = {
            "Samba": 445,
            "NFS": 2049,
            "Syncthing": 22000,
            "MQTT": 1883,
            "ZeroTier": 9993
        }
        
        status = {}
        for service, port in ports.items():
            try:
                result = subprocess.run(
                    ["netstat", "-tuln"],
                    capture_output=True,
                    text=True
                )
                is_listening = str(port) in result.stdout
                status[service] = "listening" if is_listening else "not listening"
                
                if not is_listening:
                    logging.warning(f"{service} not listening on port {port}")
                    self.mqtt_client.publish(
                        "storage/alerts/network",
                        f"{service} not listening on port {port}"
                    )
            except Exception as e:
                logging.error(f"Error checking {service} port {port}: {e}")
                status[service] = "error"
        return status

    def run(self):
        """Main monitoring loop"""
        logging.info("Starting storage node monitoring")
        
        while True:
            try:
                # Check all monitored aspects
                service_status = self.check_service_status()
                disk_usage = self.check_disk_space()
                network_status = self.check_network_connectivity()
                
                # Publish overall status
                status = {
                    "timestamp": datetime.now().isoformat(),
                    "services": service_status,
                    "disk": disk_usage,
                    "network": network_status
                }
                
                self.mqtt_client.publish(
                    "storage/status",
                    str(status)
                )
                
                # Wait before next check
                time.sleep(60)
                
            except KeyboardInterrupt:
                logging.info("Monitoring stopped by user")
                break
            except Exception as e:
                logging.error(f"Error in monitoring loop: {e}")
                time.sleep(10)  # Wait before retry on error

if __name__ == "__main__":
    monitor = StorageMonitor()
    monitor.run()
