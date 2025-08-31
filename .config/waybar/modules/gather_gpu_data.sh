#!/bin/bash
set -eo pipefail

# Cache file location
CACHE_FILE="/tmp/waybar_gpu_cache.json"

# Color codes (hexadecimal)
GREEN_HEX="00FF00"
YELLOW_HEX="FFFF00"
RED_HEX="FF0000"
GREY_HEX="AAAAAA"

# Define a default PCI_ID to explicitly check GPU
TARGET_PCI_ID="0000:28:00.0"

# Function to get GPU information by iterating through sysfs and finding relevant paths
get_gpu_info() {
    local pci_id="$TARGET_PCI_ID"
    local drm_card_path=""
    local hwmon_path=""
    local sensors_chip_name=""
    local abs_device_path=""

    # Iterate through /sys/class/drm cards to find the device matching the PCI_ID
    # Once found, try to locate the corresponding hwmon path.
    for card_dir in /sys/class/drm/card*; do
        if [ -L "$card_dir/device" ]; then
            local current_abs_device_path=$(readlink -f "$card_dir/device")
            if [[ "$current_abs_device_path" == *"$pci_id"* ]]; then
                drm_card_path="$card_dir"
                abs_device_path="$current_abs_device_path"

                # Now that we have abs_device_path, find the corresponding hwmon_path
                for hwmon_dir in /sys/class/hwmon/hwmon*; do
                    if [ -L "$hwmon_dir/device" ]; then
                        local device_path_hwmon=$(readlink -f "$hwmon_dir/device")
                        if [[ "$device_path_hwmon" == "$abs_device_path" ]]; then
                            # Verify it has power info, which indicates it's likely the main GPU hwmon
                            if [ -f "$hwmon_dir/power1_average" ]; then
                                hwmon_path="$hwmon_dir"
                                break # Found hwmon, exit inner loop
                            fi
                        fi
                    fi
                done
                break # Found drm card and hwmon, exit outer loop
            fi
        fi
    done

    # Derive sensors chip name using the found abs_device_path 
    if [ -n "$abs_device_path" ]; then
        # Extract the PCI segment (e.g., "2800" from "0000:28:00.0")
        local pci_id_segment=$(basename "$abs_device_path" | awk -F'[:.]' '{print $2 $3}')

        # Use sensors -u to find the chip name that matches this PCI segment
        sensors_chip_name=$(sensors -u | awk -v pci_segment="${pci_id_segment}" '
            /^(amdgpu|nvidia|nvme|radeon)-pci-/ {
                # Extract the PCI part from the chip name (e.g., "2800" from "amdgpu-pci-2800")
                match($0, /^(amdgpu|nvidia|nvme|radeon)-pci-([0-9a-f]+)/, arr);
                if (arr[2] == pci_segment) {
                    print substr($0, RSTART, RLENGTH);
                    exit;
                }
            }' | tr -d '/')
    fi

    # Output all collected info
    echo "$pci_id"
    echo "$drm_card_path"
    echo "$hwmon_path"
    echo "$sensors_chip_name"
    echo "$abs_device_path"
}

# Helper function to convert bytes to GiB (floor)
bytes_to_gib_floor() {
    local bytes="$1"
    echo "$((${bytes} / (1024 * 1024 * 1024)))"
}

# Execute the get_gpu_info function and store results in an array
readarray -t gpu_info_array < <(get_gpu_info)

# Assign array values to descriptive variables
PCI_ID="${gpu_info_array[0]}"
DRMCARD_PATH="${gpu_info_array[1]}"
HWMON_PATH="${gpu_info_array[2]}"
SENSORS_CHIP_NAME="${gpu_info_array[3]}"
ABS_DEVICE_PATH="${gpu_info_array[4]}"

# Check if essential GPU information was retrieved successfully
if [ -z "$ABS_DEVICE_PATH" ] || [ -z "$PCI_ID" ] || [ -z "$DRMCARD_PATH" ] || [ -z "$HWMON_PATH" ] || [ -z "$SENSORS_CHIP_NAME" ]; then
    echo "Error: Could not retrieve ALL essential GPU information or relevant paths. One or more paths/values are empty." >&2
    cat <<EOF > "$CACHE_FILE"
{
    "temperature": "N/A", "temperature_color": "${GREY_HEX}",
    "usage": "N/A", "usage_color": "${GREY_HEX}",
    "wattage": "N/A", "wattage_color": "${GREY_HEX}",
    "vram_free_gib": "N/A", "vram_color": "${GREY_HEX}"
}
EOF
    exit 1
fi

# Initialize variables for GPU metrics and their colors
temperature="N/A"
temperature_color="$GREY_HEX"
gpu_usage="N/A"
usage_color="$GREY_HEX"
wattage="N/A"
wattage_color="$GREY_HEX"
remaining_gib="N/A"
vram_color="$GREY_HEX"

# Get temperature
if [ -n "$SENSORS_CHIP_NAME" ]; then
    temperature_raw=$(sensors "${SENSORS_CHIP_NAME}" | grep "edge" | awk '{print $2}' | cut -c2- | tr -d '\n' 2>/dev/null)
    if [ -n "$temperature_raw" ]; then
        temperature=${temperature_raw%.*} # Remove decimal part
        if (( temperature < 65 )); then temperature_color="$GREEN_HEX"; else temperature_color="$RED_HEX"; fi
    fi
fi

# Get GPU usage percentage
if [ -f "${ABS_DEVICE_PATH}/gpu_busy_percent" ]; then
    gpu_usage_raw=$(cat "${ABS_DEVICE_PATH}/gpu_busy_percent" | tr -d '\n' 2>/dev/null)
    if [ -n "$gpu_usage_raw" ]; then
        gpu_usage=$(printf "%d" "$gpu_usage_raw") # Ensure integer
        if (( gpu_usage < 95 )); then usage_color="$GREEN_HEX"; else usage_color="$RED_HEX"; fi
    fi
fi

# Get wattage
if [ -f "${HWMON_PATH}/power1_average" ]; then
    wattage_raw=$(cat "${HWMON_PATH}/power1_average" | tr -d '\n' 2>/dev/null)
    if [ -n "$wattage_raw" ]; then
        wattage=$((wattage_raw / 1000000)) # Convert microwatts to watts
        if (( wattage < 150 )); then wattage_color="$GREEN_HEX"; else wattage_color="$RED_HEX"; fi
    fi
fi

# Get VRAM usage
total_bytes=""
used_bytes=""
if [ -f "${ABS_DEVICE_PATH}/mem_info_vram_total" ]; then total_bytes=$(cat "${ABS_DEVICE_PATH}/mem_info_vram_total" 2>/dev/null); fi
if [ -f "${ABS_DEVICE_PATH}/mem_info_vram_used" ]; then used_bytes=$(cat "${ABS_DEVICE_PATH}/mem_info_vram_used" 2>/dev/null); fi

if [ -n "$total_bytes" ] && [ -n "$used_bytes" ]; then
    total_gib=$(bytes_to_gib_floor "$total_bytes")
    used_gib=$(bytes_to_gib_floor "$used_bytes")
    remaining_gib=$((total_gib - used_gib))
    # Color coding for VRAM based on remaining free GiB
    if (( remaining_gib <= 4 )); then vram_color="$RED_HEX"; elif (( remaining_gib <= 8 )); then vram_color="$YELLOW_HEX"; else vram_color="$GREEN_HEX"; fi
fi

# Output the GPU metrics to the cache file in JSON format
cat <<EOF > "$CACHE_FILE"
{
    "temperature": "${temperature}", "temperature_color": "${temperature_color}",
    "usage": "${gpu_usage}", "usage_color": "${usage_color}",
    "wattage": "${wattage}", "wattage_color": "${wattage_color}",
    "vram_free_gib": "${remaining_gib}", "vram_color": "${vram_color}"
}
EOF
