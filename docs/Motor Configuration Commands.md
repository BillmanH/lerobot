Even using UV, you have to activate the env first. 


```bash
python lerobot/scripts/find_motors_bus_port.py
```

ports found: 
| Port            | Description |
|-----------------|-------------|
| `/dev/ttyACM1`    | Follower            |
| `/dev/ttyACM0`    |  Leader           |

```bash
sudo chmod 666 /dev/ttyACM0a
sudo chmod 666 /dev/ttyACM1
```

```bash
python lerobot/scripts/configure_motor.py --port COM3 --brand feetech --model sts3215 --baudrate 1000000 --ID 2
```

```bash
python lerobot/scripts/control_robot.py --robot.type=so101 --robot.cameras={} --control.type=calibrate  --control.arms="[\"main_follower\"]"
```

lerobot-setup-motors \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem585A0076841 


```bash
python lerobot/scripts/control_robot.py --robot.type=so100 --control.type=calibrate
```
