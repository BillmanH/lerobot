import sys
from pathlib import Path

# Add the src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from lerobot_edge.robots.so101_follower import SO101Follower, SO101FollowerConfig
from lerobot_edge.teleoperators.so101_leader import SO101Leader, SO101LeaderConfig

import yaml

# Load configuration
with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

print("=== Testing Follower Connection ===")
try:
    follower_config = SO101FollowerConfig(
        port=local_configurations["follower_port"],
        id="my_awesome_follower_arm",
    )
    follower = SO101Follower(follower_config)
    print(f"Connecting to follower on {local_configurations['follower_port']}...")
    follower.connect(calibrate=False)
    print("✓ Follower connected successfully")
    
    # Test getting observation
    obs = follower.get_observation()
    print(f"✓ Follower observation: {list(obs.keys())}")
    
    follower.disconnect()
    print("✓ Follower disconnected")
except Exception as e:
    print(f"✗ Follower error: {e}")

print("\n=== Testing Leader Connection ===")
try:
    leader_config = SO101LeaderConfig(
        port=local_configurations["leader_port"],
        id="my_awesome_leader_arm",
    )
    leader = SO101Leader(leader_config)
    print(f"Connecting to leader on {local_configurations['leader_port']}...")
    leader.connect(calibrate=False)
    print("✓ Leader connected successfully")
    
    # Test getting action
    action = leader.get_action()
    print(f"✓ Leader action: {list(action.keys())}")
    
    leader.disconnect()
    print("✓ Leader disconnected")
except Exception as e:
    print(f"✗ Leader error: {e}")

print("\n=== Test Complete ===")
