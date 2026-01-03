import sys
from pathlib import Path

# Add the src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from lerobot_edge.constants import HF_LEROBOT_CALIBRATION, TELEOPERATORS, ROBOTS
from lerobot_edge.teleoperators.so101_leader import SO101Leader, SO101LeaderConfig
from lerobot_edge.robots.so101_follower import SO101Follower, SO101FollowerConfig

import yaml

print("=== Calibration File Locations ===\n")
print(f"Base calibration directory: {HF_LEROBOT_CALIBRATION}")
print(f"Teleoperators subdirectory: {TELEOPERATORS}")
print(f"Robots subdirectory: {ROBOTS}\n")

# Load configuration
with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

# Check leader calibration
leader_id = "my_awesome_leader_arm"
leader_calibration_dir = HF_LEROBOT_CALIBRATION / TELEOPERATORS / "so101_leader"
leader_calibration_file = leader_calibration_dir / f"{leader_id}.json"

print("=== Leader (Teleoperator) ===")
print(f"Expected calibration file: {leader_calibration_file}")
print(f"File exists: {leader_calibration_file.exists()}")
if leader_calibration_file.exists():
    print(f"File size: {leader_calibration_file.stat().st_size} bytes")
    print(f"Contents preview:")
    print(leader_calibration_file.read_text()[:500])
else:
    print("⚠ No calibration file found! Run 04_configure_leader.py")

print("\n=== Follower (Robot) ===")
follower_id = "my_awesome_follower_arm"
follower_calibration_dir = HF_LEROBOT_CALIBRATION / ROBOTS / "so101_follower"
follower_calibration_file = follower_calibration_dir / f"{follower_id}.json"

print(f"Expected calibration file: {follower_calibration_file}")
print(f"File exists: {follower_calibration_file.exists()}")
if follower_calibration_file.exists():
    print(f"File size: {follower_calibration_file.stat().st_size} bytes")
    print(f"Contents preview:")
    print(follower_calibration_file.read_text()[:500])
else:
    print("⚠ No calibration file found! Run 03_configure_follower.py")

print("\n=== All Calibration Files ===")
if HF_LEROBOT_CALIBRATION.exists():
    for path in HF_LEROBOT_CALIBRATION.rglob("*.json"):
        print(f"  {path}")
else:
    print("  No calibration directory found")
