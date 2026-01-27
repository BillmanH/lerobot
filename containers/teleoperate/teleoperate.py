import sys
import time
import os
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import threading
import logging

# Add the src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from lerobot_edge.robots.so101_follower import SO101Follower, SO101FollowerConfig
from lerobot_edge.teleoperators.so101_leader import SO101Leader, SO101LeaderConfig

import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Load configuration
with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

# Get calibration directory from environment or use default local configs
calibration_dir = os.getenv("HF_LEROBOT_CALIBRATION", "./configs")
calibration_path = Path(calibration_dir)

# Create robot and teleoperator configurations
follower_config = SO101FollowerConfig(
    port=local_configurations["follower_port"],
    id="my_awesome_follower_arm",
    calibration_dir=calibration_path,
)

leader_config = SO101LeaderConfig(
    port=local_configurations["leader_port"],
    id="my_awesome_leader_arm",
    calibration_dir=calibration_path,
)logger.info("Connecting to follower...")
    follower.connect(calibrate=False)
    logger.info("[OK] Follower connected")
except Exception as e:
    logger.error(f"[FAIL] Failed to connect to follower: {e}")
    logger.error("Troubleshooting:")
    logger.error("1. Check that follower is powered on")
    logger.error("2. Verify port in local_configurations.yaml")
    logger.error("3. Run 01_setup_motors_follower.py first")
    logger.error("4. Try running 05_test_connection.py for diagnostics")
    sys.exit(1)

try:
    logger.info("Connecting to leader...")
    leader.connect(calibrate=False)
    logger.info("[OK] Leader connected")
except Exception as e:
    logger.error(f"[FAIL] Failed to connect to leader: {e}")
    logger.error("Troubleshooting:")
    logger.error("1. Check that leader is powered on")
    logger.error("2. Verify port in local_configurations.yaml")
    logger.error("3. Run 02_setup_motors_leader.py first")
    logger.errorr.connect(calibrate=False)
    print("✓ Leader connected")
except Exception as e:
    print(f"✗ Failed to connect to leader: {e}")
    print("\nTroubleshooting:")
    print("1. Check that leader is powered on")
    print("2. Verify port in local_configurations.yaml")
    print("3. Run 02_setup_motors_leader.py first")
    print("4. Try running 05_test_connection.py for diagnostics")
    follower.disconnect()
    sys.exit(1)

if not follower.is_connected or not leader.is_connected:
    raise ValueError("Failed to connect to follower or leader!")

# Shared state for HTTP endpoint
device_state = {
    "follower_connected": follower.is_connected,
    "leader_connected": leader.is_connected,
    "last_action": None,
    "last_update": time.time()
}

class USBSignalHandler(BaseHTTPRequestHandler):
    """HTTP handler to expose USB device signals for AKRI/AIO Data Flows"""
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy"}).encode())
        
        elif self.path == '/ready':
            ready = device_state["follower_connected"] and device_state["leader_connected"]
            self.send_response(200 if ready else 503)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"ready": ready}).encode())
        
        elif self.path == '/signals':
            # Return current USB device signals
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(device_state).encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

def run_http_server():
    """Run HTTP server in background thread"""
    port = int(os.getenv("HTTP_PORT", "8080"))
    server = HTTPServer(('0.0.0.0', port), USBSignalHandler)
    logger.info(f"HTTP server listening on port {port}")
    server.serve_forever()

# Start HTTP server in background
http_thread = threading.Thread(target=run_http_server, daemon=True)
http_thread.start()

logger.info("LeRobot Telemetry Listener started")
logger.info("HTTP endpoint available at :8080/signals")
logger.info("Press Ctrl+C to stop")
logger.info("Logging telemetry data every 5 seconds...")

try:loop_count = 0
    log_interval = 500  # Log every 500 loops (~5 seconds at 100Hz)
    
    while True:
        # Read action from leader (USB signals)
        action = leader.get_action()
        
        # Update shared state
        device_state["last_action"] = action.tolist() if hasattr(action, 'tolist') else list(action)
        device_state["last_update"] = time.time()
        device_state["follower_connected"] = follower.is_connected
        device_state["leader_connected"] = leader.is_connected
        
        # Log telemetry data periodically
        loop_count += 1
        if loop_count % log_interval == 0:
            logger.info(f"Telemetry: leader_action={device_state['last_action']}, "
                       f"follower_connected={follower.is_connected}, "
                       f"leader_connected={leader.is_connected}")
            loop_count = 0
        
        # Small delay to prevent overwhelming the motors
        time.sleep(0.01)  # 100Hz read loop

except KeyboardInterrupt:
    logger.info("Stopping telemetry listener...")

finally:
    # Cleanup
    logger.info("Disconnecting devices...")
    follower.disconnect()
    leader.disconnect()
    logger.infor.disconnect()
    print("Done!")
