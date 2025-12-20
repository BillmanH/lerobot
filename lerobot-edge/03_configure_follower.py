import sys
from pathlib import Path

# Add the src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from lerobot_edge.robots.so101_follower import SO101Follower, SO101FollowerConfig

import yaml

with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

config = SO101FollowerConfig(
    port=local_configurations["follower_port"],
    id="my_awesome_follower_arm",
)

follower = SO101Follower(config)
follower.connect(calibrate=False)
follower.calibrate()
follower.disconnect()
