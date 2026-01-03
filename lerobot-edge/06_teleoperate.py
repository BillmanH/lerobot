import sys
import time
from pathlib import Path

# Add the src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from lerobot_edge.robots.so101_follower import SO101Follower, SO101FollowerConfig
from lerobot_edge.teleoperators.so101_leader import SO101Leader, SO101LeaderConfig

import yaml

# Load configuration
with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

# Create robot and teleoperator configurations
follower_config = SO101FollowerConfig(
    port=local_configurations["follower_port"],
    id="my_awesome_follower_arm",
)

leader_config = SO101LeaderConfig(
    port=local_configurations["leader_port"],
    id="my_awesome_leader_arm",
)

# Initialize devices
follower = SO101Follower(follower_config)
leader = SO101Leader(leader_config)

# Connect to devices
print("Connecting to follower...")
follower.connect(calibrate=False)

print("Connecting to leader...")
leader.connect(calibrate=False)

if not follower.is_connected or not leader.is_connected:
    raise ValueError("Failed to connect to follower or leader!")

print("\nTeleoperation started. Press Ctrl+C to stop.")
print("Move the leader arm to control the follower arm.\n")

try:
    while True:
        # Get action from leader (teleoperator)
        action = leader.get_action()
        
        # Send action to follower (robot)
        follower.send_action(action)
        
        # Small delay to prevent overwhelming the motors
        time.sleep(0.01)  # 100Hz control loop

except KeyboardInterrupt:
    print("\n\nStopping teleoperation...")

finally:
    # Cleanup
    print("Disconnecting devices...")
    follower.disconnect()
    leader.disconnect()
    print("Done!")
