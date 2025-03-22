#!/bin/bash

# Get the available memory in GiB
available_memory=$(free -g | awk '/Mem/ {print $7}')
#available_memory=$(free -g | awk '/Mem/ {printf "%.2f\n", $7}')
# Set the threshold value in GiB for color change
threshold=8.0

# Determine the color based on available memory and threshold
if (( $(awk -v x="$available_memory" -v y="$threshold" 'BEGIN {print (x < y)}') )); then
    color="#FF0000"  # Red color for low memory
else
    color="#00FF00"  # Green color for sufficient memory
fi

# Print the available memory in the specified color
echo "<span foreground='$color'>RAM: $available_memory GiB</span>"
