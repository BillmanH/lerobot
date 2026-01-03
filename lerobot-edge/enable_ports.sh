#!/bin/bash

# Script to check and enable serial ports defined in local_configurations.yaml
# This script checks if the ports are readable/writable and enables them if needed

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/local_configurations.yaml"

echo "=========================================="
echo "Serial Port Permission Checker & Enabler"
echo "=========================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

echo "Reading configuration from: $CONFIG_FILE"
echo ""

# Extract ports from YAML file
FOLLOWER_PORT=$(grep "follower_port:" "$CONFIG_FILE" | sed 's/.*"\(.*\)".*/\1/')
LEADER_PORT=$(grep "leader_port:" "$CONFIG_FILE" | sed 's/.*"\(.*\)".*/\1/')

echo "Detected ports:"
echo "  - Follower port: $FOLLOWER_PORT"
echo "  - Leader port: $LEADER_PORT"
echo ""

# Function to check and enable a port
check_and_enable_port() {
    local PORT=$1
    local PORT_NAME=$2
    
    echo "----------------------------------------"
    echo "Checking $PORT_NAME ($PORT)..."
    echo "----------------------------------------"
    
    # Check if port exists
    if [ ! -e "$PORT" ]; then
        echo "WARNING: Port $PORT does not exist (device not connected?)"
        echo ""
        return 1
    fi
    
    echo "Port exists: ✓"
    
    # Check if port is readable and writable
    if [ -r "$PORT" ] && [ -w "$PORT" ]; then
        echo "Port is readable: ✓"
        echo "Port is writable: ✓"
        echo "Port $PORT is already accessible!"
        echo ""
        return 0
    else
        echo "Port permissions check:"
        if [ ! -r "$PORT" ]; then
            echo "  - Readable: ✗"
        else
            echo "  - Readable: ✓"
        fi
        if [ ! -w "$PORT" ]; then
            echo "  - Writable: ✗"
        else
            echo "  - Writable: ✓"
        fi
        echo ""
        
        # Get current permissions and owner
        echo "Current port details:"
        ls -l "$PORT"
        echo ""
        
        # Attempt to fix permissions
        echo "Attempting to enable port with sudo..."
        
        # Add user to dialout group if not already a member
        if ! groups | grep -q "dialout"; then
            echo "Adding current user ($USER) to 'dialout' group..."
            sudo usermod -a -G dialout "$USER"
            echo "User added to dialout group. You may need to log out and back in for this to take effect."
            echo ""
        else
            echo "User is already in 'dialout' group: ✓"
            echo ""
        fi
        
        # Set port permissions
        echo "Setting port permissions..."
        sudo chmod 666 "$PORT"
        echo "Permissions updated: ✓"
        echo ""
        
        # Verify the changes
        echo "Verifying changes..."
        if [ -r "$PORT" ] && [ -w "$PORT" ]; then
            echo "Port $PORT is now accessible: ✓"
            echo ""
            return 0
        else
            echo "ERROR: Port still not accessible after permission changes"
            echo "You may need to:"
            echo "  1. Log out and log back in (if you were just added to dialout group)"
            echo "  2. Unplug and replug the device"
            echo "  3. Check if the device is working properly"
            echo ""
            return 1
        fi
    fi
}

# Check and enable both ports
FOLLOWER_SUCCESS=0
LEADER_SUCCESS=0

check_and_enable_port "$FOLLOWER_PORT" "Follower port" || FOLLOWER_SUCCESS=$?
check_and_enable_port "$LEADER_PORT" "Leader port" || LEADER_SUCCESS=$?

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
if [ $FOLLOWER_SUCCESS -eq 0 ]; then
    echo "Follower port ($FOLLOWER_PORT): ✓ READY"
else
    echo "Follower port ($FOLLOWER_PORT): ✗ NEEDS ATTENTION"
fi

if [ $LEADER_SUCCESS -eq 0 ]; then
    echo "Leader port ($LEADER_PORT): ✓ READY"
else
    echo "Leader port ($LEADER_PORT): ✗ NEEDS ATTENTION"
fi
echo ""

if [ $FOLLOWER_SUCCESS -eq 0 ] && [ $LEADER_SUCCESS -eq 0 ]; then
    echo "All ports are ready! ✓"
    exit 0
else
    echo "Some ports need attention. Please review the output above."
    exit 1
fi
