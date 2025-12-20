# lerobot-edge

Lightweight robot control package for edge devices - no ML/training dependencies.

## Overview

`lerobot-edge` is a stripped-down version of LeRobot designed specifically for edge devices (Raspberry Pi, Jetson Nano, etc.). It includes only the essential components for robot control, teleoperation, and data collection - without the heavy ML dependencies like PyTorch.

**Package size:** ~200-300MB (vs ~8-10GB for full LeRobot)

## Installation

### Prerequisites

- Python 3.10 or 3.11
- UV package manager (recommended) or pip

### Quick Start

```bash
# Install UV (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

# Clone the repository
git clone https://github.com/yourusername/lerobot-edge.git
cd lerobot-edge

# Create virtual environment
uv venv --python python3.11
source .venv/bin/activate

# Install dependencies
uv pip install -r requirements-edge.txt

# Or install from pyproject.toml
uv pip install -e .
```

### Alternative: Using pip

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements-edge.txt
```

## Configuration

Edit `local_configurations.yaml` to match your robot's setup:

```yaml
follower_port: "/dev/ttyACM0"  # Change to your follower robot's port
leader_port: "/dev/ttyACM1"    # Change to your leader robot's port
```

## Usage

### 1. Setup Motors

```bash
# Setup follower arm motors
python 01_setup_motors_follower.py

# Setup leader arm motors (for teleoperation)
python 02_setup_motors_leader.py
```

### 2. Calibrate Robot

```bash
# Calibrate follower arm
python 03_configure_follower.py

# Calibrate leader arm
python 04_configure_leader.py
```

### 3. Use in Python

```python
from lerobot_edge.robots import SO101Follower, SO101FollowerConfig

# Configure robot
config = SO101FollowerConfig(
    port="/dev/ttyACM0",
    id="my_robot"
)

# Connect and control
robot = SO101Follower(config)
robot.connect()

# Your robot control code here
robot.disconnect()
```

## What's Included

- ✅ Motor control (Feetech, Dynamixel)
- ✅ Camera capture (OpenCV)
- ✅ Robot implementations (SO101, SO100, etc.)
- ✅ Teleoperation
- ✅ Basic data recording
- ✅ Action replay

## What's NOT Included

- ❌ PyTorch / ML training
- ❌ Policy models
- ❌ Dataset processing
- ❌ Simulation environments
- ❌ Advanced visualization

For training and ML features, use the full `lerobot` package on a cloud/workstation machine.

## Supported Robots

- SO101 Follower
- SO101 Leader
- SO100
- Koch
- And more...

## Troubleshooting

### Motor SDK Issues

If you get `ModuleNotFoundError: No module named 'scservo_sdk'`:

```bash
uv pip install feetech-servo-sdk==1.0.0 --no-deps
```

### Permission Issues (Linux)

Add your user to the dialout group for serial port access:

```bash
sudo usermod -a -G dialout $USER
# Log out and back in for changes to take effect
```

## Development

This package is designed for:
- Data collection on edge devices
- Teleoperation
- Robot control without ML inference

For model training and evaluation, transfer collected data to a machine with the full `lerobot` package.

## License

Apache-2.0

## Links

- Full LeRobot: https://github.com/huggingface/lerobot
- Documentation: See `separation_of_concerns.md` in main repo
- Issues: https://github.com/huggingface/lerobot/issues
