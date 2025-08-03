#!/bin/bash
set -eo pipefail

CACHE_FILE="/tmp/waybar_gpu_cache.json"

if [ -f "$CACHE_FILE" ]; then
    wattage=$(jq -r '.wattage' "$CACHE_FILE")
    wattage_color_hex=$(jq -r '.wattage_color' "$CACHE_FILE")

    # Output ONLY the wattage with Pango markup for color
    echo "<span foreground='#${wattage_color_hex}'>${wattage}W</span>"
else
    echo "<span foreground='#AAAAAA'>N/AW</span>"
fi
