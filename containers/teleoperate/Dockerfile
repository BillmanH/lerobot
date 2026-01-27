# Copyright 2025 The HuggingFace Inc. team. All rights reserved.
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

# Dockerfile for teleoperate_mqtt container
# This container runs the teleoperation script for SO101 robot arms

ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}-slim

# Configure environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    libusb-1.0-0-dev \
    udev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY containers/teleoperate_mqtt/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the source code and script
COPY containers/teleoperate_mqtt/src /app/src
COPY containers/teleoperate_mqtt/teleoperate.py /app/
COPY containers/teleoperate_mqtt/local_configurations.yaml /app/

# Set up udev rules for USB device access (optional, for documentation)
# Note: This requires --privileged flag or specific device permissions when running
RUN echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="*", MODE="0666"' > /etc/udev/rules.d/99-lerobot.rules

# Create a non-root user
RUN useradd --create-home --shell /bin/bash lerobot && \
    chown -R lerobot:lerobot /app

USER lerobot

# Default command
CMD ["python", "teleoperate.py"]
