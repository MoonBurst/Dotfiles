#!/bin/bash
#set -x # REMOVE THIS LINE AFTER THE SCRIPT IS WORKING CORRECTLY

# Define a default PCI_ID if you want to explicitly target one
# Leave empty to auto-detect /sys/class/drm/card0
# Set to your 7900 XTX's PCI ID for explicit monitoring
TARGET_PCI_ID="0000:28:00.0"

get_gpu_info() {
    local pci_id=""
    local drm_card_path=""
    local hwmon_path=""
    local gpu_name=""
    local sensors_chip_name=""

    # 1. Determine the PCI ID of the target GPU
    if [ -z "$TARGET_PCI_ID" ]; then
        # Try to find the PCI ID associated with /sys/class/drm/card0 first
        if [ -L "/sys/class/drm/card0/device" ]; then
            local card0_device_path=$(readlink -f "/sys/class/drm/card0/device")
            # Extract PCI ID (e.g., 0000:01:00.0) from the full device path
            pci_id=$(echo "$card0_device_path" | grep -oP 'pci[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]' | tail -n 1 | cut -c5-)
            drm_card_path="/sys/class/drm/card0" # Explicitly set card0 path if found
        fi

        # Fallback if card0 wasn't found or couldn't get its PCI ID
        if [ -z "$pci_id" ]; then
            # Fallback to lspci's first detected display controller
            local pci_id_short=$(lspci -m | grep -E 'VGA compatible controller|3D controller|Display controller' | head -n 1 | awk '{print $1}')
            if [ -n "$pci_id_short" ]; then
                pci_id="0000:${pci_id_short}" # Prepend 0000: for full ID
            else
                echo "Error: Could not determine GPU PCI ID." >&2
                return 1 # Return with error status
            fi
        fi
    else
        # Use the explicitly set TARGET_PCI_ID
        pci_id="$TARGET_PCI_ID"
    fi

    # Ensure pci_id is in full 0000:XX:YY.Z format for consistent use
    if ! [[ "$pci_id" =~ ^[0-9a-f]{4}: ]]; then
        pci_id="0000:${pci_id}"
    fi

    # If drm_card_path was not set by the card0 logic, find it now based on pci_id
    if [ -z "$drm_card_path" ]; then
        for card_dir in /sys/class/drm/card*; do
            if [ -L "$card_dir/device" ]; then
                local device_path=$(readlink -f "$card_dir/device")
                if [[ "$device_path" == *"$pci_id"* ]]; then
                    drm_card_path="$card_dir"
                    break
                fi
            fi
        done
    fi

    # 2. Find corresponding /sys/class/hwmon/hwmonY path for power data
    for hwmon_dir in /sys/class/hwmon/hwmon*; do
        if [ -L "$hwmon_dir/device" ]; then
            local device_path=$(readlink -f "$hwmon_dir/device")
            if [[ "$device_path" == *"$pci_id"* ]]; then
                hwmon_path="$hwmon_dir"
                # Check for power1_average specifically, as not all hwmon devices have it
                if [ -f "$hwmon_path/power1_average" ]; then
                    break # Found the right hwmon with power data
                fi
            fi
        fi
    done

    local lspci_output=$(lspci -v -s "$pci_id")

    # 3. Get GPU Name (Prioritize Subsystem name, then general controller name)
    # Try to extract from Subsystem line first for a more specific name
    gpu_name=$(echo "$lspci_output" | grep -i "Subsystem:" | head -n 1 | sed -E 's/.*Subsystem: (.*)/\1/' | sed -E 's/\[[^]]*\]//g' | xargs)

    if [[ -z "$gpu_name" ]]; then
        # Fallback to the general controller name if Subsystem not found or empty
        gpu_name=$(echo "$lspci_output" | grep -i "VGA compatible controller\|3D controller\|Display controller" | head -n 1 | sed -E 's/.*: (.*) \(rev.*\)/\1/' | sed 's/ (rev a.)//' | sed 's/ (prog-if 00 \[VGA controller\])//' | sed -E 's/\[.*\] (.*)/\1/' | sed -E 's/.*\] ([^)]*)/\1/')
        # Further clean up GPU name (replace multiple spaces/brackets)
        gpu_name=$(echo "$gpu_name" | sed -E 's/\[[^]]*\]//g' | sed 's/[[:space:]][[:space:]]*/ /g' | xargs)
    fi

    if [[ -z "$gpu_name" ]]; then
        gpu_name="GPU" # Final fallback name
    fi

    # 4. Get sensors chip name (e.g., amdgpu-pci-2800)
    # Extract only the last four hex digits for the sensors chip name match, like "2800" from "0000:28:00.0"
    # This specifically matches your `amdgpu-pci-2800` output in `sensors -u`.
    local pci_id_segment_for_sensors=$(echo "$pci_id" | awk -F'[:.]' '{print $2 $3}') # Robustly get "2800" from "0000:28:00.0"

    sensors_chip_name=$(sensors -u | awk -v pci_id_segment="${pci_id_segment_for_sensors}" '
        # Match lines that start with a known GPU chip type and "pci-"
        # The [0-9a-f]+ part matches the "2800"
        /^(amdgpu|nvidia|nvme|radeon)-pci-[0-9a-f]+/ {
            # Perform the match
            match($0, /^(amdgpu|nvidia|nvme|radeon)-pci-[0-9a-f]+/);
            # Extract the full chip name (e.g., "amdgpu-pci-2800")
            chip_name_full = substr($0, RSTART, RLENGTH);

            # Extract just the "2800" part for comparison
            extracted_pci_part = chip_name_full;
            sub(/^(amdgpu|nvidia|nvme|radeon)-pci-/, "", extracted_pci_part);

            # Compare the extracted PCI part with our target segment
            if (extracted_pci_part == pci_id_segment) {
                print chip_name_full; # Print the full chip name (e.g., "amdgpu-pci-2800")
                exit; # Exit after finding the first match to avoid processing further
            }
        }' | tr -d '/') # Remove any trailing slashes if present

    # Output each value on a new line for readarray
    echo "$pci_id"
    echo "$drm_card_path"
    echo "$hwmon_path"
    echo "$gpu_name"
    echo "$sensors_chip_name"
}

# --- Main script starts here ---

# Call the function and read the returned values line by line into an array
# Using readarray for robust multi-line output handling
readarray -t gpu_info_array < <(get_gpu_info)

# Assign array elements to individual variables
PCI_ID="${gpu_info_array[0]}"
DRMCARD_PATH="${gpu_info_array[1]}"
HWMON_PATH="${gpu_info_array[2]}"
GPU_NAME="${gpu_info_array[3]}"
SENSORS_CHIP_NAME="${gpu_info_array[4]}"

# Check if essential info was successfully retrieved
if [ -z "$PCI_ID" ] || [ -z "$DRMCARD_PATH" ]; then
    echo "Error: Could not retrieve GPU information or relevant paths. Check script or PCI ID."
    exit 1
fi

# GPU Temperature
# If SENSORS_CHIP_NAME is found, use it directly for precise reading.
if [ -n "$SENSORS_CHIP_NAME" ]; then
    # Use the specific chip name, then grep for "edge" temperature
    temperature=$(sensors "${SENSORS_CHIP_NAME}" | grep "edge" | awk '{print $2}' | cut -c2- | tr -d '\n')
else
    # Fallback temperature detection if specific chip name not found (shouldn't happen now)
    # This might still pick up other GPUs if multiple "gpu" entries exist
    temperature=$(sensors | grep "gpu" | { read gpu_output; sensors | grep "$gpu_output" -A 5 | grep edge | awk '{print $2}' | cut -c2-; } | tr -d '\n')
fi

# Remove decimal part and set color
temperature=${temperature%.*}
if (( temperature < 65 )); then
  temperature_color='#00FF00'
else
  temperature_color='#f53c3c'
fi

# GPU Usage
if [ -f "${DRMCARD_PATH}/device/gpu_busy_percent" ]; then
    gpu_usage_raw=$(cat "${DRMCARD_PATH}/device/gpu_busy_percent" | tr -d '\n')
    gpu_usage=$(printf "%d" "$gpu_usage_raw") # Ensure it's an integer
else
    gpu_usage="N/A" # Set to N/A if file not found
    usage_color='#AAAAAA' # Grey out if data not available
fi

if [[ "$gpu_usage" != "N/A" ]]; then
    if (( gpu_usage < 95 )); then
      usage_color='#00FF00'
    else
      usage_color='#f53c3c'
    fi
fi


# Wattage
if [ -f "${HWMON_PATH}/power1_average" ]; then
    wattage_raw=$(cat "${HWMON_PATH}/power1_average" | tr -d '\n')
    wattage=$((wattage_raw / 1000000)) # Convert microwatts to watts
else
    wattage="N/A" # Set to N/A if file not found
    wattage_color='#AAAAAA' # Grey out if data not available
fi

if [[ "$wattage" != "N/A" ]]; then
    if (( wattage < 150 )); then
      wattage_color='#00FF00'
    else
      wattage_color='#f53c3c'
    fi
fi

# Display GPU temperature and usage with color coding
echo -e "<span foreground='$temperature_color'>GPU: $temperature°C</span> <span foreground='$usage_color'>$gpu_usage%</span> <span foreground='$wattage_color'>$wattage W</span>"
