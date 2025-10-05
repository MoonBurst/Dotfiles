#!/bin/bash
available_memory=$(free -g | awk '/Mem/ {print $7}')
# Set the thresholds in GiB (as integers)
RED_THRESHOLD=8
WARN_THRESHOLD=16

LOW="#FF0000"     # Red color for critically low memory (< 8 GiB)
WARN="#FFA500"    # Orange/Amber color for warning memory (>= 8 GiB and < 16 GiB)
SUFFICIENT="#00FF00" # Green color for sufficient memory (>= 16 GiB)

if (( available_memory < RED_THRESHOLD )); then
    color="$LOW"
elif (( available_memory < WARN_THRESHOLD )); then
    color="$WARN"
else
    color="$SUFFICIENT"
fi
# Print the available memory in the specified color.
echo "<span foreground='$color'>RAM: $available_memory GiB</span>"
