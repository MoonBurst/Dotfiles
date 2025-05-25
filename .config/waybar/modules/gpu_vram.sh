#!/bin/bash

# Script to display remaining VRAM for a specified AMD GPU in GiB with color
# Outputting hex color for Waybar, rounded down to nearest GiB

# Color codes (hexadecimal)
GREEN="#00FF00"
YELLOW="#FFFF00"
RED="#FF0000"

# Default to card0 if no argument is provided
card="${1:-card0}"
sysfs_path="/sys/class/drm/${card}/device"

# Check if the card exists
if [ ! -d "${sysfs_path}" ]; then
    echo "Error: GPU card '${card}' not found."
    echo "Available cards in /sys/class/drm:"
    ls /sys/class/drm/
    exit 1
fi

# Get total VRAM in bytes
total_bytes=$(cat "${sysfs_path}/mem_info_vram_total" 2>/dev/null)
if [ -z "$total_bytes" ]; then
    echo "Error: Could not read total VRAM for ${card}."
    exit 1
fi

# Get used VRAM in bytes
used_bytes=$(cat "${sysfs_path}/mem_info_vram_used" 2>/dev/null)
if [ -z "$used_bytes" ]; then
    echo "Error: Could not read used VRAM for ${card}."
    exit 1
fi

# Function to convert bytes to GiB (integer part only)
bytes_to_gib_floor() {
    local bytes="$1"
    echo "$((${bytes} / (1024 * 1024 * 1024)))"
}

# Calculate total and used VRAM in whole GiB
total_gib=$(bytes_to_gib_floor "$total_bytes")
used_gib=$(bytes_to_gib_floor "$used_bytes")

# Calculate remaining VRAM
remaining_gib=$((total_gib - used_gib))

# Determine color based on remaining VRAM
color_code="$GREEN" # Start with green
remaining_gib_num=$remaining_gib #already an integer

if (( remaining_gib_num <= 12 && remaining_gib_num >= 6 )); then
    color_code="$YELLOW"
elif (( remaining_gib_num < 6 )); then
    color_code="$RED"
fi

echo -e "<span foreground='$color_code'>VRAM: ${remaining_gib} GiB</span>"
