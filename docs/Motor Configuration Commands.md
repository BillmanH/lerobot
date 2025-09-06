```bash
python lerobot/scripts/find_motors_bus_port.py
```

```bash
python lerobot/scripts/configure_motor.py --port COM3 --brand feetech --model sts3215 --baudrate 1000000 --ID 2
```

```bash
python lerobot/scripts/control_robot.py --robot.type=so101 --robot.cameras={} --control.type=calibrate  --control.arms="[\"main_follower\"]"
```

```bash
python lerobot/scripts/control_robot.py --robot.type=so100 --control.type=calibrate
```
