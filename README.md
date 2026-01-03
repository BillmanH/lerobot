# **B**ill's **R**robot **O**perator

A direct fork of [The official Lerobot](https://github.com/huggingface/lerobot), but with some modifications that are specific to my use case: 

## 1 Separation of "edge" processes and "cloud" processes.
* edge processes are operating the robot, managing servos and USB ports, generating telemetry
* cloud processes are better for systems like Azure _(not yet implemented)_
  * Training models
  * Visualizing datasets (not live)
  * Real time analytics in tools Graphana or Fabric

## 2 Running on a smaller footprint at the edge
* I'm building for a smaller machine like a NUC or a RaspberyPi.
* The main goal is that you `git pull` this repo onto the edge machine and run the python scripts.  
* Using UV as opposed to miniconda because I like it better.
* Running pure python as opposed to the command line arguments so that I have more extensibility and control.

## Edge Setup Scripts (lerobot-edge/)

These scripts are designed to run on lightweight edge devices and use minimal dependencies (`yaml`, `time`, standard library only).

| Script | Purpose |
|--------|---------|
| `00_find_usb_port.py` | Detects which USB port your robot motors are connected to by identifying the difference when you disconnect/reconnect the cable |
| `01_setup_motors_follower.py` | Initializes and configures the motors on the follower arm (robot that executes actions) |
| `02_setup_motors_leader.py` | Initializes and configures the motors on the leader arm (teleoperator that generates commands) |
| `03_configure_follower.py` | Calibrates the follower arm motors and saves calibration data to `~/.cache/huggingface/lerobot/calibration/robots/so101_follower/` |
| `04_configure_leader.py` | Calibrates the leader arm motors and saves calibration data to `~/.cache/huggingface/lerobot/calibration/teleoperators/so101_leader/` |
| `05_check_calibration.py` | Diagnostic tool to verify calibration files exist in the correct locations and displays their paths |
| `05_test_connection.py` | Tests connection to both follower and leader devices separately to identify which one is failing |
| `06_teleoperate.py` | Main teleoperation script - reads positions from leader arm and sends them to follower arm in real-time (~100Hz control loop) |
| `enable_ports.sh` | Bash script to check and enable serial port permissions for the ports defined in `local_configurations.yaml` |
| `backup_configs.sh` | Bash script to backup calibration files to USB/SD drives for easy transfer between machines |



