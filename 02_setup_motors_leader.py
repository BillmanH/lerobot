from lerobot.teleoperators.so101_leader import SO101Leader, SO101LeaderConfig
import yaml

with open("local_configurations.yaml", "r") as f:
    local_configurations = yaml.safe_load(f)

config = SO101LeaderConfig(
    port=local_configurations['leader_port'],
    id="my_awesome_leader_arm",
)
leader = SO101Leader(config)
leader.setup_motors()