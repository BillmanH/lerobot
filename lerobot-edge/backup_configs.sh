#!/bin/bash

# Script to backup robot calibration configuration files to USB/SD drive
# This script finds configuration files created by 03 and 04 scripts and backs them up

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/calibration"

echo "=========================================="
echo "Robot Configuration Backup Tool"
echo "=========================================="
echo ""

# Configuration files to backup
FOLLOWER_CONFIG="my_awesome_follower_arm.json"
LEADER_CONFIG="my_awesome_leader_arm.json"

echo "Looking for configuration files..."
echo ""

# Find the configuration files
FOLLOWER_PATH=""
LEADER_PATH=""

# Search in common calibration directories
# Note: Follower is a robot, Leader is a teleoperator (different paths)
SEARCH_DIRS=(
    "$HOME/.cache/huggingface/lerobot/calibration/robots/so101_follower"      # Follower calibration
    "$HOME/.cache/huggingface/lerobot/calibration/teleoperators/so101_leader"  # Leader calibration (correct)
    "$HOME/.cache/huggingface/lerobot/calibration/robots/so101_leader"        # Legacy/incorrect leader location
    "$CACHE_DIR/so101_follower"
    "$CACHE_DIR/so101_leader"
    "$CACHE_DIR"
    "$SCRIPT_DIR/.cache/calibration/so101_follower"
    "$SCRIPT_DIR/.cache/calibration/so101_leader"
)

echo "Searching for follower configuration ($FOLLOWER_CONFIG)..."
echo "Search directories:"
for dir in "${SEARCH_DIRS[@]}"; do
    echo "  - $dir"
    if [ -f "$dir/$FOLLOWER_CONFIG" ]; then
        FOLLOWER_PATH="$dir/$FOLLOWER_CONFIG"
        echo "  ✓ Found: $FOLLOWER_PATH"
        break
    fi
done
if [ -z "$FOLLOWER_PATH" ]; then
    echo "  ✗ Not found in any search directory"
fi
echo ""

echo "Searching for leader configuration ($LEADER_CONFIG)..."
echo "Search directories:"
for dir in "${SEARCH_DIRS[@]}"; do
    echo "  - $dir"
    if [ -f "$dir/$LEADER_CONFIG" ]; then
        LEADER_PATH="$dir/$LEADER_CONFIG"
        echo "  ✓ Found: $LEADER_PATH"
        break
    fi
done
if [ -z "$LEADER_PATH" ]; then
    echo "  ✗ Not found in any search directory"
fi

echo ""

# Check if we found the files
if [ -z "$FOLLOWER_PATH" ] && [ -z "$LEADER_PATH" ]; then
    echo "ERROR: No configuration files found!"
    echo "Please run the calibration scripts (03_configure_follower.py and 04_configure_leader.py) first."
    exit 1
fi

if [ -z "$FOLLOWER_PATH" ]; then
    echo "WARNING: Follower configuration not found. Only leader config will be backed up."
fi

if [ -z "$LEADER_PATH" ]; then
    echo "WARNING: Leader configuration not found. Only follower config will be backed up."
fi

echo ""
echo "=========================================="
echo "Detecting USB/SD drives..."
echo "=========================================="
echo ""

# Detect removable drives (USB/SD)
# This works on Linux systems
DRIVES=()
DRIVE_LABELS=()

# Method 1: Using lsblk (most reliable on Linux)
if command -v lsblk &> /dev/null; then
    while IFS= read -r line; do
        # Parse lsblk output: NAME, SIZE, TYPE, MOUNTPOINT, LABEL
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        mountpoint=$(echo "$line" | awk '{print $3}')
        label=$(echo "$line" | awk '{print $4}')
        
        if [ -n "$mountpoint" ] && [ "$mountpoint" != "MOUNTPOINT" ]; then
            DRIVES+=("$mountpoint")
            if [ -n "$label" ] && [ "$label" != "LABEL" ]; then
                DRIVE_LABELS+=("$label ($size) - $mountpoint")
            else
                DRIVE_LABELS+=("Unlabeled ($size) - $mountpoint")
            fi
        fi
    done < <(lsblk -no NAME,SIZE,MOUNTPOINT,LABEL -I 8 -d | tail -n +2 | while read -r disk rest; do
        lsblk -no NAME,SIZE,MOUNTPOINT,LABEL "/dev/$disk" | grep -E "part|disk" | grep -v "^$disk "
    done)
fi

# Method 2: Fallback - check common mount points
if [ ${#DRIVES[@]} -eq 0 ]; then
    echo "Using fallback method to detect drives..."
    for mount_point in /media/$USER/* /mnt/*; do
        if [ -d "$mount_point" ] && mountpoint -q "$mount_point" 2>/dev/null; then
            size=$(df -h "$mount_point" | tail -1 | awk '{print $2}')
            DRIVES+=("$mount_point")
            DRIVE_LABELS+=("$(basename "$mount_point") ($size) - $mount_point")
        fi
    done
fi

# Check if any drives were found
if [ ${#DRIVES[@]} -eq 0 ]; then
    echo "ERROR: No USB or SD drives detected!"
    echo ""
    echo "Would you like to mount a drive now? (y/n)"
    read -p "> " mount_choice
    
    if [ "$mount_choice" != "y" ] && [ "$mount_choice" != "Y" ]; then
        echo "Exiting. Please mount a drive and run this script again."
        exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo "Manual Drive Mounting"
    echo "=========================================="
    echo ""
    
    # List all block devices
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
    echo ""
    
    # Prompt for device
    read -p "Enter the device to mount (e.g., sdb1, sdc1): " device_name
    
    # Validate device exists
    if [ ! -b "/dev/$device_name" ]; then
        echo "ERROR: Device /dev/$device_name does not exist!"
        exit 1
    fi
    
    # Create mount point
    MOUNT_POINT="/mnt/usb_backup_$(date +%s)"
    echo ""
    echo "Creating mount point: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
    
    # Detect filesystem type
    FS_TYPE=$(lsblk -no FSTYPE "/dev/$device_name")
    echo "Detected filesystem: $FS_TYPE"
    echo ""
    
    # Mount the drive
    echo "Mounting /dev/$device_name to $MOUNT_POINT..."
    if [ -n "$FS_TYPE" ]; then
        sudo mount -t "$FS_TYPE" "/dev/$device_name" "$MOUNT_POINT"
    else
        sudo mount "/dev/$device_name" "$MOUNT_POINT"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ Drive mounted successfully!"
        echo ""
        # Add the newly mounted drive to our list
        DRIVES=("$MOUNT_POINT")
        size=$(df -h "$MOUNT_POINT" | tail -1 | awk '{print $2}')
        DRIVE_LABELS=("Manually mounted ($size) - $MOUNT_POINT")
    else
        echo "✗ Failed to mount drive!"
        exit 1
    fi
fi

# Display available drives
echo "Available drives:"
echo ""
for i in "${!DRIVES[@]}"; do
    echo "  [$((i+1))] ${DRIVE_LABELS[$i]}"
done
echo ""

# Prompt user to select a drive
while true; do
    read -p "Select drive number [1-${#DRIVES[@]}]: " selection
    
    # Validate input
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#DRIVES[@]}" ]; then
        SELECTED_DRIVE="${DRIVES[$((selection-1))]}"
        break
    else
        echo "Invalid selection. Please enter a number between 1 and ${#DRIVES[@]}."
    fi
done

echo ""
echo "Selected drive: $SELECTED_DRIVE"
echo ""

# Create backup directory on the drive
BACKUP_DIR="$SELECTED_DRIVE/lerobot-configs"

echo "Saving to: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"

# Copy configuration files
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

if [ -n "$FOLLOWER_PATH" ]; then
    echo "Copying $(basename "$FOLLOWER_PATH")..."
    if sudo cp "$FOLLOWER_PATH" "$BACKUP_DIR/"; then
        echo "  ✓ Saved"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

if [ -n "$LEADER_PATH" ]; then
    echo "Copying $(basename "$LEADER_PATH")..."
    if sudo cp "$LEADER_PATH" "$BACKUP_DIR/"; then
        echo "  ✓ Saved"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

if [ -f "$SCRIPT_DIR/local_configurations.yaml" ]; then
    echo "Copying local_configurations.yaml..."
    if sudo cp "$SCRIPT_DIR/local_configurations.yaml" "$BACKUP_DIR/"; then
        echo "  ✓ Saved"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ Done! Files saved to: $BACKUP_DIR"
    exit 0
else
    echo "⚠ Some files failed. Check output above."
    exit 1
fi