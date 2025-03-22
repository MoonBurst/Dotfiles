#!/bin/bash

# Command to get the GPU temperature
temperature=$(sensors | grep "gpu" | { read gpu_output; sensors | grep "$gpu_output" -A 5 | grep edge | awk '{print $2}' | cut -c2-; })

# Remove decimal part to compare
temperature=${temperature%.*}
if (( temperature < 65 )); then
  temperature_color='#00FF00'
else
  temperature_color='#f53c3c'
fi



gpu_usage=$(cat /sys/class/drm/card*/device/gpu_busy_percent)
if (( gpu_usage < 95 )); then
  usage_color='#00FF00'
else
  usage_color='#f53c3c'
fi

#(cat /sys/class/hwmon/$POWERREADOUT/power1_average)
wattage=$(cat /sys/class/hwmon/hwmon*/power1_average)
wattage=$((wattage / 1000000))
if (( wattage < 150 )); then
  wattage_color='#00FF00'  # Corrected the variable name to wattage_color
else
  wattage_color='#f53c3c'  # Corrected the variable name to wattage_color
fi

# Display GPU temperature and usage with color coding
echo -e "<span foreground='$temperature_color'>GPU: $temperature°C</span>" "<span foreground='$usage_color'>$gpu_usage%</span>" "<span foreground='$wattage_color'>$wattage W</span>"
