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
SEARCH_DIRS=(
    "$CACHE_DIR/so101_follower"
    "$CACHE_DIR/so101_leader"
    "$CACHE_DIR"
    "$SCRIPT_DIR/.cache/calibration/so101_follower"
    "$SCRIPT_DIR/.cache/calibration/so101_leader"
)

echo "Searching for follower configuration ($FOLLOWER_CONFIG)..."
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -f "$dir/$FOLLOWER_CONFIG" ]; then
        FOLLOWER_PATH="$dir/$FOLLOWER_CONFIG"
        echo "  Found: $FOLLOWER_PATH"
        break
    fi
done

echo "Searching for leader configuration ($LEADER_CONFIG)..."
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -f "$dir/$LEADER_CONFIG" ]; then
        LEADER_PATH="$dir/$LEADER_CONFIG"
        echo "  Found: $LEADER_PATH"
        break
    fi
done

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
    echo "Please ensure:"
    echo "  1. A USB drive or SD card is plugged in"
    echo "  2. The drive is mounted"
    echo "  3. You have permissions to access it"
    echo ""
    echo "You can manually mount a drive and run this script again."
    exit 1
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
BACKUP_DIR="$SELECTED_DRIVE/lerobot_configs_backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_SUBDIR="$BACKUP_DIR/backup_$TIMESTAMP"

echo "Creating backup directory: $BACKUP_SUBDIR"
mkdir -p "$BACKUP_SUBDIR"

# Copy configuration files
echo ""
echo "=========================================="
echo "Backing up configuration files..."
echo "=========================================="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

if [ -n "$FOLLOWER_PATH" ]; then
    echo "Copying follower configuration..."
    if cp "$FOLLOWER_PATH" "$BACKUP_SUBDIR/"; then
        echo "  ✓ Follower config backed up: $BACKUP_SUBDIR/$(basename "$FOLLOWER_PATH")"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed to backup follower config"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

if [ -n "$LEADER_PATH" ]; then
    echo "Copying leader configuration..."
    if cp "$LEADER_PATH" "$BACKUP_SUBDIR/"; then
        echo "  ✓ Leader config backed up: $BACKUP_SUBDIR/$(basename "$LEADER_PATH")"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed to backup leader config"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

# Also backup the local_configurations.yaml file
if [ -f "$SCRIPT_DIR/local_configurations.yaml" ]; then
    echo "Copying local_configurations.yaml..."
    if cp "$SCRIPT_DIR/local_configurations.yaml" "$BACKUP_SUBDIR/"; then
        echo "  ✓ Local configurations backed up: $BACKUP_SUBDIR/local_configurations.yaml"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed to backup local_configurations.yaml"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

# Create a backup info file
INFO_FILE="$BACKUP_SUBDIR/backup_info.txt"
{
    echo "Robot Configuration Backup"
    echo "=========================="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "User: $USER"
    echo ""
    echo "Backed up files:"
    [ -n "$FOLLOWER_PATH" ] && echo "  - $(basename "$FOLLOWER_PATH") (from $FOLLOWER_PATH)"
    [ -n "$LEADER_PATH" ] && echo "  - $(basename "$LEADER_PATH") (from $LEADER_PATH)"
    [ -f "$SCRIPT_DIR/local_configurations.yaml" ] && echo "  - local_configurations.yaml"
    echo ""
    echo "Backup location: $BACKUP_SUBDIR"
} > "$INFO_FILE"

echo ""
echo "Backup info saved: $INFO_FILE"

echo ""
echo "=========================================="
echo "Backup Summary"
echo "=========================================="
echo "Successful: $SUCCESS_COUNT file(s)"
echo "Failed: $FAIL_COUNT file(s)"
echo ""
echo "Backup location: $BACKUP_SUBDIR"
echo ""

# List backed up files
echo "Backed up files:"
ls -lh "$BACKUP_SUBDIR"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ All configurations backed up successfully!"
    exit 0
else
    echo "⚠ Some files failed to backup. Please check the output above."
    exit 1
fi
