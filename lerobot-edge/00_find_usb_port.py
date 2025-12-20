#!/usr/bin/env python

# Copyright 2024 The HuggingFace Inc. team. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Helper script to find the USB port associated with your robot's motors.

This script helps you identify which USB port your motors are connected to
by detecting the difference when you disconnect and reconnect the USB cable.

Usage:
    python 00_find_usb_port.py
"""

import sys
from pathlib import Path

# Add src directory to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from lerobot_edge.find_port import find_port


if __name__ == "__main__":
    print("=" * 60)
    print("USB Port Finder for Robot Motors")
    print("=" * 60)
    print()
    
    find_port()
    
    print()
    print("=" * 60)
    print("Next steps:")
    print("1. Update the port in 'local_configurations.yaml'")
    print("2. Run '01_setup_motors_follower.py' to configure follower motors")
    print("3. Run '02_setup_motors_leader.py' to configure leader motors")
    print("=" * 60)
