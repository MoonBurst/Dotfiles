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

# Check the current CPU package power using powercap
#package_power=$(sudo s-tui -t | grep -o 'package-0,0: [0-9.]*' | cut -d " " -f 2)
#package_power_int=$(printf "%.0f" "$package_power")
#if (( package_power_int < 60 )); then
#  power_color='#00FF00'  # Set color for power consumption
#else
#  power_color='#f53c3c'  # Set color for power consumption when triggered
#fi

# Display CPU temperature, usage, and power consumption in watts with color coding
echo -e "<span foreground='$temperature_color'>CPU: $temperature°C</span>" "<span foreground='$usage_color'>$cpu_usage%</span>" 
#"<span foreground='$power_color'>$package_power W</span>"


