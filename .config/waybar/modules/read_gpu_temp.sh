#!/bin/bash
set -eo pipefail

CACHE_FILE="/tmp/waybar_gpu_cache.json"

if [ -f "$CACHE_FILE" ]; then
    temp=$(jq -r '.temperature' "$CACHE_FILE")
    temp_color_hex=$(jq -r '.temperature_color' "$CACHE_FILE")

    # Output ONLY the temperature with Pango markup for color
    echo "<span foreground='#${temp_color_hex}'>${temp}°C</span>"
else
    echo "<span foreground='#AAAAAA'>N/A°C</span>"
fi
