from lerobot.robots.so101_follower import SO101Follower, SO101FollowerConfig

import yaml

with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

config = SO101FollowerConfig(
    port=local_configurations.follower_port,
    id="my_awesome_follower_arm",
)
follower = SO101Follower(config)
follower.setup_motors()