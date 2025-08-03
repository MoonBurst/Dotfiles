#!/bin/bash
set -eo pipefail

CACHE_FILE="/tmp/waybar_gpu_cache.json"
DEFAULT_COLOR="AAAAAA" # Define a default grey color for safety
GREEN_HEX="00FF00"
RED_HEX="FF0000"
PADDING_COLOR_HEX="262626" # Color for the padding character

if [ -f "$CACHE_FILE" ]; then
    # Read raw values from the cache for display and tooltip
    temp_raw=$(jq -r '.temperature' "$CACHE_FILE" || echo "N/A")
    temp_color_hex=$(jq -r '.temperature_color' "$CACHE_FILE" || echo "$DEFAULT_COLOR")

    usage_raw=$(jq -r '.usage' "$CACHE_FILE" || echo "N/A")
    usage_color_hex=$(jq -r '.usage_color' "$CACHE_FILE" || echo "$DEFAULT_COLOR")

    wattage_raw=$(jq -r '.wattage' "$CACHE_FILE" || echo "N/A")
    wattage_color_hex=$(jq -r '.wattage_color' "$CACHE_FILE" || echo "$DEFAULT_COLOR")

    vram_free_raw=$(jq -r '.vram_free_gib' "$CACHE_FILE" || echo "N/A")
    vram_color_hex=$(jq -r '.vram_color' "$CACHE_FILE" || echo "$DEFAULT_COLOR")

    # --- IMPORTANT: Ensure colors are never empty ---
    [ -z "$temp_color_hex" ] && temp_color_hex="$DEFAULT_COLOR"
    [ -z "$usage_color_hex" ] && usage_color_hex="$DEFAULT_COLOR"
    [ -z "$wattage_color_hex" ] && wattage_color_hex="$DEFAULT_COLOR"
    [ -z "$vram_color_hex" ] && vram_color_hex="$DEFAULT_COLOR"

    # --- Function to format a number with colored padding and unit ---
    # $1: raw_value, $2: length, $3: color_hex, $4: unit_string
    function format_metric {
        local raw_value=$1
        local length=$2
        local color_hex=$3
        local unit_string=$4
        local output_string=""
        
        if [[ "$raw_value" =~ ^[0-9]+$ ]]; then
            local padded_value=$(printf "%0${length}d" "$raw_value")
            local found_number=false
            local digit_span=""
            
            for (( i=0; i<${length}; i++ )); do
                local char=${padded_value:i:1}
                if [ "$char" != "0" ] || [ "$found_number" = true ]; then
                    digit_span+="<span foreground='#${color_hex}'>${char}</span>"
                    found_number=true
                else
                    digit_span+="<span foreground='#${PADDING_COLOR_HEX}'>${char}</span>"
                fi
            done
            # Special case for "0" where we need to show a single digit
            if [ "$raw_value" -eq 0 ] && [ "$found_number" = false ]; then
                digit_span=""
                for (( i=0; i<length-1; i++ )); do
                    digit_span+="<span foreground='#${PADDING_COLOR_HEX}'>0</span>"
                done
                digit_span+="<span foreground='#${color_hex}'>0</span>"
            fi
            output_string="${digit_span}<span foreground='#${color_hex}'>${unit_string}</span>"
        else
            output_string=$(printf "%${length}s" "N/A")
        fi
        echo "$output_string"
    }

    # --- Format each metric using the new function ---
    temp_formatted=$(format_metric "$temp_raw" 3 "$temp_color_hex" "°C")
    usage_formatted=$(format_metric "$usage_raw" 3 "$usage_color_hex" "%")
    wattage_formatted=$(format_metric "$wattage_raw" 3 "$wattage_color_hex" "W")
    vram_formatted=$(format_metric "$vram_free_raw" 2 "$vram_color_hex" " GiB")


    # --- Determine overall GPU status color ---
    overall_gpu_color="$GREEN_HEX"
    if [[ "$temp_color_hex" == "$RED_HEX" ]] || \
       [[ "$usage_color_hex" == "$RED_HEX" ]] || \
       [[ "$wattage_color_hex" == "$RED_HEX" ]] || \
       [[ "$vram_color_hex" == "$RED_HEX" ]]; then
        overall_gpu_color="$RED_HEX"
    fi

    # --- Construct the combined text string with Pango markup ---
    
    combined_text="<span foreground='#${overall_gpu_color}'>GPU:</span>"
    combined_text+="<span>${temp_formatted}</span> "
    combined_text+="<span>${usage_formatted}</span> "
    combined_text+="<span>${wattage_formatted}</span> "
    combined_text+="<span foreground='#${vram_color_hex}'>VRAM: ${vram_formatted}</span>"


    # For the tooltip, use the raw values
    tooltip_text="GPU Temp: ${temp_raw}°C\n"
    tooltip_text+="GPU Usage: ${usage_raw}%\n"
    tooltip_text+="GPU Power: ${wattage_raw}W\n"
    tooltip_text+="GPU VRAM Free: ${vram_free_raw} GiB"

    # Output Waybar JSON
    echo "${combined_text}"
else
    # Fallback if cache file doesn't exist
    echo "{\"text\": \"N/A\", \"tooltip\": \"GPU data N/A\", \"class\": \"gpu-grey\"}"
fi
