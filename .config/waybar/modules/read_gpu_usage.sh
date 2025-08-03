#!/bin/bash
set -eo pipefail

CACHE_FILE="/tmp/waybar_gpu_cache.json"

if [ -f "$CACHE_FILE" ]; then
    usage=$(jq -r '.usage' "$CACHE_FILE")
    usage_color_hex=$(jq -r '.usage_color' "$CACHE_FILE")

    # Output ONLY the usage with Pango markup for color
    echo "<span foreground='#${usage_color_hex}'>${usage}%</span>"
else
    echo "<span foreground='#AAAAAA'>N/A%</span>"
fi
