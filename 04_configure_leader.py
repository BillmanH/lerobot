from lerobot.robots.so101_follower import SO101Follower, SO101FollowerConfig

follower_port = '/dev/ttyACM0'  # Change this to your leader robot's port
leader_port = '/dev/ttyACM1'  # Change this to your follower


config = SO101FollowerConfig(
    port=leader_port,
    id="my_awesome_follower_arm",
)

follower = SO101Follower(config)
follower.connect(calibrate=False)
follower.calibrate()
follower.disconnect()