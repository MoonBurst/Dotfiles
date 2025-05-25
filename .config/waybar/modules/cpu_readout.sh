#!/bin/bash

# Get temperature
temperature=$(sensors | grep "Tctl" | awk '{print int($2 + 0.5)}')
if (( temperature < 70 )); then
  temperature_color='#00FF00'
else
  temperature_color='#f53c3c'
fi

# Get CPU usage percentage
cpu_usage=$(top -bn1 | awk '/%Cpu/ {print 100 - $8}' | cut -d "." -f1)
if (( cpu_usage < 80 )); then
  usage_color='#00FF00'
else
  usage_color='#f53c3c'
fi

# Get CPU package power using powercap (using a safer method)
#package_power_raw=$(
#  if command -v s-tui &>/dev/null; then
#    sudo s-tui -t | grep -m 1 'package-0,0:' 2>/dev/null
#  else
#    echo ""
#  fi
#)

# Extract the numeric power value
package_power=$(echo "$package_power_raw" | sed -n "s/.*package-0,0: \([0-9.]*\).*/\1/p")

# Check if package_power is a valid number
if [[ -z "$package_power" || "$package_power" == "" ]]; then
  power_color='#FFFFFF'
  package_power_display="N/A" # Display "N/A"
else
  package_power_int=$(printf "%.0f" "$package_power" 2>/dev/null)
  if (( package_power_int < 60 )); then
    power_color='#00FF00'  # Set color for power consumption
  else
    power_color='#f53c3c'  # Set color for power consumption when triggered
  fi
  package_power_display="${package_power_int}W" #if it is a number, display with W
fi

# Display CPU temperature, usage, and power consumption in watts with color coding for Waybar
echo -e "<span color='$temperature_color'>CPU: $temperature°C</span> <span color='$usage_color'>$cpu_usage%</span>" 
#<span color='$power_color'>${package_power_display}</span>"
