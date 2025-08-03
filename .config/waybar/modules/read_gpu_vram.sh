#!/bin/bash
set -eo pipefail

CACHE_FILE="/tmp/waybar_gpu_cache.json" # Ensure this path is consistent

if [ -f "$CACHE_FILE" ]; then
    vram_free=$(jq -r '.vram_free_gib' "$CACHE_FILE")
    vram_color_hex=$(jq -r '.vram_color' "$CACHE_FILE") # Get hex color from cache

    # Output "VRAM: X GiB" with Pango markup for color
    echo "<span foreground='#${vram_color_hex}'>VRAM: ${vram_free} GiB</span>"
else
    # Fallback if cache file doesn't exist or data is N/A
    echo "<span foreground='#AAAAAA'>VRAM: N/A GiB</span>" # Grey for N/A
fi
