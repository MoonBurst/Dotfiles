#!/bin/bash
set -x # Enable debug output - REMOVE THIS LINE AFTER THE SCRIPT IS WORKING CORRECTLY

# Script to display comprehensive AMD GPU information (Temp, Usage, Wattage, VRAM)
# Outputting hex color for Waybar, rounded down to nearest GiB for VRAM

# Color codes (hexadecimal)
GREEN="#00FF00"
YELLOW="#FFFF00"
RED="#FF0000"
GREY="#AAAAAA" # For N/A values

# TARGET_PCI_ID can be left empty to auto-detect /sys/class/drm/card0's PCI ID
# Set to your 7900 XTX's PCI ID for explicit monitoring if needed
TARGET_PCI_ID="" # e.g., "0000:28:00.0" for a specific card

get_gpu_info() {
    local pci_id=""
    local drm_card_path=""
    local hwmon_path=""
    local gpu_name=""
    local sensors_chip_name=""
    local abs_device_path="" # New variable for the absolute device path

    echo "DEBUG: Starting get_gpu_info function." >&2

    # 1. Determine the PCI ID of the target GPU
    if [ -z "$TARGET_PCI_ID" ]; then
        echo "DEBUG: TARGET_PCI_ID is empty, attempting auto-detection." >&2
        if [ -L "/sys/class/drm/card0/device" ]; then
            abs_device_path=$(readlink -f "/sys/class/drm/card0/device")
            pci_id=$(echo "$abs_device_path" | grep -oP 'pci[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]' | tail -n 1 | cut -c5-)
            drm_card_path="/sys/class/drm/card0"
            echo "DEBUG: Found card0 device path (absolute): $abs_device_path" >&2
            echo "DEBUG: Extracted PCI ID from card0: $pci_id" >&2
        fi

        if [ -z "$pci_id" ]; then
            echo "DEBUG: PCI ID from card0 not found or empty, falling back to lspci." >&2
            local pci_id_short=$(lspci -m | grep -E 'VGA compatible controller|3D controller|Display controller' | head -n 1 | awk '{print $1}')
            if [ -n "$pci_id_short" ]; then
                pci_id="0000:${pci_id_short}"
                echo "DEBUG: Found PCI ID from lspci: $pci_id" >&2
                # If falling back to lspci, try to set drm_card_path and abs_device_path based on it
                for card_dir in /sys/class/drm/card*; do
                    if [ -L "$card_dir/device" ]; then
                        local temp_abs_device_path=$(readlink -f "$card_dir/device")
                        if [[ "$temp_abs_device_path" == *"$pci_id"* ]]; then
                            drm_card_path="$card_dir"
                            abs_device_path="$temp_abs_device_path"
                            echo "DEBUG: Found drm_card_path: $drm_card_path and abs_device_path: $abs_device_path based on lspci PCI ID." >&2
                            break
                        fi
                    fi
                done
            else
                echo "Error: Could not determine GPU PCI ID using card0 or lspci." >&2
                return 1
            fi
        fi
    else
        pci_id="$TARGET_PCI_ID"
        echo "DEBUG: Using explicitly set TARGET_PCI_ID: $pci_id" >&2
        # If TARGET_PCI_ID is set, find its corresponding drm_card_path and abs_device_path
        for card_dir in /sys/class/drm/card*; do
            if [ -L "$card_dir/device" ]; then
                local temp_abs_device_path=$(readlink -f "$card_dir/device")
                if [[ "$temp_abs_device_path" == *"$pci_id"* ]]; then
                    drm_card_path="$card_dir"
                    abs_device_path="$temp_abs_device_path"
                    echo "DEBUG: Found drm_card_path: $drm_card_path and abs_device_path: $abs_device_path for TARGET_PCI_ID." >&2
                    break
                fi
            fi
        done
        if [ -z "$drm_card_path" ]; then
            echo "Error: Could not find drm_card_path for TARGET_PCI_ID: $TARGET_PCI_ID" >&2
            return 1
        fi
    fi

    if ! [[ "$pci_id" =~ ^[0-9a-f]{4}: ]]; then
        pci_id="0000:${pci_id}"
        echo "DEBUG: Normalized PCI ID to full format: $pci_id" >&2
    fi

    echo "DEBUG: Final drm_card_path: $drm_card_path" >&2
    echo "DEBUG: Final abs_device_path: $abs_device_path" >&2

    # 2. Find corresponding /sys/class/hwmon/hwmonY path for power data
    hwmon_path="" # Ensure it's clear before loop
    echo "DEBUG: Searching for hwmon_path for PCI ID: $pci_id" >&2
    for hwmon_dir in /sys/class/hwmon/hwmon*; do
        if [ -L "$hwmon_dir/device" ]; then
            local device_path=$(readlink -f "$hwmon_dir/device")
            if [[ "$device_path" == *"$pci_id"* ]]; then
                hwmon_path="$hwmon_dir"
                echo "DEBUG: Potential hwmon_path found: $hwmon_path" >&2
                if [ -f "$hwmon_path/power1_average" ]; then
                    echo "DEBUG: Found power1_average, confirming hwmon_path: $hwmon_path" >&2
                    break
                else
                    echo "DEBUG: $hwmon_path does not have power1_average, continuing search." >&2
                    hwmon_path="" # Reset if not suitable
                fi
            fi
        fi
    done

    local lspci_output=$(lspci -v -s "$pci_id")
    echo "DEBUG: lspci output for $pci_id acquired." >&2

    # 3. Get GPU Name
    gpu_name=$(echo "$lspci_output" | grep -i "Subsystem:" | head -n 1 | sed -E 's/.*Subsystem: (.*)/\1/' | sed -E 's/\[[^]]*\]//g' | xargs)
    if [[ -z "$gpu_name" ]]; then
        gpu_name=$(echo "$lspci_output" | grep -i "VGA compatible controller|3D controller|Display controller" | head -n 1 | sed -E 's/.*: (.*) \(rev.*\)/\1/' | sed 's/ (rev a.)//' | sed 's/ (prog-if 00 \[VGA controller\])//' | sed -E 's/\[.*\] (.*)/\1/' | sed -E 's/\[[^]]*\]//g' | sed 's/[[:space:]][[:space:]]*/ /g' | xargs)
    fi
    if [[ -z "$gpu_name" ]]; then
        gpu_name="GPU"
    fi
    echo "DEBUG: GPU Name: $gpu_name" >&2

    # 4. Get sensors chip name
    local pci_id_segment_for_sensors=$(echo "$pci_id" | awk -F'[:.]' '{print $2 $3}')
    sensors_chip_name=$(sensors -u | awk -v pci_id_segment="${pci_id_segment_for_sensors}" '/^(amdgpu|nvidia|nvme|radeon)-pci-[0-9a-f]+/ {match($0, /^(amdgpu|nvidia|nvme|radeon)-pci-[0-9a-f]+/); chip_name_full = substr($0, RSTART, RLENGTH); extracted_pci_part = chip_name_full; sub(/^(amdgpu|nvidia|nvme|radeon)-pci-/, "", extracted_pci_part); if (extracted_pci_part == pci_id_segment) {print chip_name_full; exit;}}' | tr -d '/')
    echo "DEBUG: Sensors Chip Name: $sensors_chip_name" >&2

    echo "DEBUG: get_gpu_info returning values." >&2
    echo "$pci_id"
    echo "$drm_card_path"
    echo "$hwmon_path"
    echo "$gpu_name"
    echo "$sensors_chip_name"
    echo "$abs_device_path" # Return the absolute device path as well
}

# Function to convert bytes to GiB (integer part only)
bytes_to_gib_floor() {
    local bytes="$1"
    echo "$((${bytes} / (1024 * 1024 * 1024)))"
}

# --- Main script starts here ---

echo "DEBUG: Main script execution started." >&2
# Call the function and read the returned values line by line into an array
readarray -t gpu_info_array < <(get_gpu_info)
echo "DEBUG: get_gpu_info returned ${#gpu_info_array[@]} elements." >&2

# Assign array elements to individual variables
PCI_ID="${gpu_info_array[0]}"
DRMCARD_PATH="${gpu_info_array[1]}"
HWMON_PATH="${gpu_info_array[2]}"
GPU_NAME="${gpu_info_array[3]}"
SENSORS_CHIP_NAME="${gpu_info_array[4]}"
ABS_DEVICE_PATH="${gpu_info_array[5]}" # Assign the new variable

echo "DEBUG: PCI_ID=$PCI_ID" >&2
echo "DEBUG: DRMCARD_PATH=$DRMCARD_PATH" >&2
echo "DEBUG: HWMON_PATH=$HWMON_PATH" >&2
echo "DEBUG: GPU_NAME=$GPU_NAME" >&2
echo "DEBUG: SENSORS_CHIP_NAME=$SENSORS_CHIP_NAME" >&2
echo "DEBUG: ABS_DEVICE_PATH=$ABS_DEVICE_PATH" >&2


# Check if essential info was successfully retrieved
if [ -z "$PCI_ID" ] || [ -z "$DRMCARD_PATH" ] || [ -z "$ABS_DEVICE_PATH" ]; then
    echo "Error: Could not retrieve GPU information or relevant paths. Check script or PCI ID." >&2
    exit 1
fi

# GPU Temperature
temperature="N/A"
temperature_color="$GREY"
echo "DEBUG: Getting GPU Temperature." >&2
if [ -n "$SENSORS_CHIP_NAME" ]; then
    temperature_raw=$(sensors "${SENSORS_CHIP_NAME}" | grep "edge" | awk '{print $2}' | cut -c2- | tr -d '\n')
    if [ -n "$temperature_raw" ]; then
        temperature=${temperature_raw%.*} # Remove decimal part
        echo "DEBUG: Raw Temperature: $temperature_raw, Processed: $temperature" >&2
    else
        echo "DEBUG: Could not get temperature from sensors chip name." >&2
    fi
fi

if [[ "$temperature" != "N/A" ]]; then
    if (( temperature < 65 )); then
      temperature_color="$GREEN"
    else
      temperature_color="$RED"
    fi
fi

# GPU Usage
gpu_usage="N/A"
usage_color="$GREY"
echo "DEBUG: Getting GPU Usage." >&2
# Use the absolute path for gpu_busy_percent as well for consistency
if [ -f "${ABS_DEVICE_PATH}/gpu_busy_percent" ]; then
    gpu_usage_raw=$(cat "${ABS_DEVICE_PATH}/gpu_busy_percent" | tr -d '\n')
    if [ -n "$gpu_usage_raw" ]; then
        gpu_usage=$(printf "%d" "$gpu_usage_raw") # Ensure it's an integer
        echo "DEBUG: Raw GPU Usage: $gpu_usage_raw, Processed: $gpu_usage" >&2
    else
        echo "DEBUG: Could not read gpu_busy_percent." >&2
    fi
else
    echo "DEBUG: gpu_busy_percent file not found at ${ABS_DEVICE_PATH}/gpu_busy_percent" >&2
fi

if [[ "$gpu_usage" != "N/A" ]]; then
    if (( gpu_usage < 95 )); then
      usage_color="$GREEN"
    else
      usage_color="$RED"
    fi
fi


# Wattage
wattage="N/A"
wattage_color="$GREY"
echo "DEBUG: Getting Wattage." >&2
if [ -f "${HWMON_PATH}/power1_average" ]; then
    wattage_raw=$(cat "${HWMON_PATH}/power1_average" | tr -d '\n')
    if [ -n "$wattage_raw" ]; then
        wattage=$((wattage_raw / 1000000)) # Convert microwatts to watts
        echo "DEBUG: Raw Wattage: $wattage_raw, Processed: $wattage W" >&2
    else
        echo "DEBUG: Could not read power1_average." >&2
    fi
else
    echo "DEBUG: power1_average file not found at ${HWMON_PATH}/power1_average" >&2
fi

if [[ "$wattage" != "N/A" ]]; then
    if (( wattage < 150 )); then
      wattage_color="$GREEN"
    else
      wattage_color="$RED"
    fi
fi

# VRAM
remaining_gib="N/A"
vram_color="$GREY"
# Use ABS_DEVICE_PATH for VRAM files
echo "DEBUG: Getting VRAM info from $ABS_DEVICE_PATH" >&2

total_bytes=""
used_bytes=""

if [ -f "${ABS_DEVICE_PATH}/mem_info_vram_total" ]; then
    total_bytes=$(cat "${ABS_DEVICE_PATH}/mem_info_vram_total" 2>/dev/null)
    echo "DEBUG: Total VRAM bytes from ${ABS_DEVICE_PATH}/mem_info_vram_total: $total_bytes" >&2
else
    echo "DEBUG: mem_info_vram_total not found at ${ABS_DEVICE_PATH}/mem_info_vram_total" >&2
fi

if [ -f "${ABS_DEVICE_PATH}/mem_info_vram_used" ]; then
    used_bytes=$(cat "${ABS_DEVICE_PATH}/mem_info_vram_used" 2>/dev/null)
    echo "DEBUG: Used VRAM bytes from ${ABS_DEVICE_PATH}/mem_info_vram_used: $used_bytes" >&2
else
    echo "DEBUG: mem_info_vram_used not found at ${ABS_DEVICE_PATH}/mem_info_vram_used" >&2
fi


if [ -n "$total_bytes" ] && [ -n "$used_bytes" ]; then
    total_gib=$(bytes_to_gib_floor "$total_bytes")
    used_gib=$(bytes_to_gib_floor "$used_bytes")
    remaining_gib=$((total_gib - used_gib))
    echo "DEBUG: Total GiB: $total_gib, Used GiB: $used_gib, Remaining GiB: $remaining_gib" >&2

    # Assuming a 20GB or 24GB VRAM card (RX 7900 XTX)
    if (( remaining_gib <= 4 )); then # Less than or equal to 4GB remaining is critical
        vram_color="$RED"
    elif (( remaining_gib <= 8 )); then # Between 5GB and 8GB remaining is yellow
        vram_color="$YELLOW"
    else # More than 8GB remaining is green
        vram_color="$GREEN"
    fi
fi


# Display all GPU information with color coding
echo "DEBUG: Attempting final output." >&2
echo -e "<span foreground='$temperature_color'>GPU: $temperature°C</span> <span foreground='$usage_color'>$gpu_usage%</span> <span foreground='$wattage_color'>$wattage W</span> <span foreground='$vram_color'>VRAM: ${remaining_gib} GiB</span>"
echo "DEBUG: Script finished." >&2
