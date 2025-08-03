#!/bin/bash
set -eo pipefail

# Cache file location
CACHE_FILE="/tmp/waybar_gpu_cache.json"

# Color codes (hexadecimal)
GREEN_HEX="00FF00"
YELLOW_HEX="FFFF00"
RED_HEX="FF0000"
GREY_HEX="AAAAAA"

# Define a default PCI_ID to explicitly target your 7900 XTX
TARGET_PCI_ID="0000:28:00.0"

get_gpu_info() {
    local pci_id="$TARGET_PCI_ID"
    local drm_card_path=""
    local hwmon_path=""
    local gpu_name=""
    local sensors_chip_name=""
    local abs_device_path=""

    if ! [[ "$pci_id" =~ ^[0-9a-f]{4}: ]]; then
        pci_id="0000:${pci_id}"
    fi

    for card_dir in /sys/class/drm/card*; do
        if [ -L "$card_dir/device" ]; then
            local temp_abs_device_path=$(readlink -f "$card_dir/device")
            if [[ "$temp_abs_device_path" == *"$pci_id"* ]]; then
                drm_card_path="$card_dir"
                abs_device_path="$temp_abs_device_path"
                break
            fi
        fi
    done

    for hwmon_dir in /sys/class/hwmon/hwmon*; do
        if [ -L "$hwmon_dir/device" ]; then
            local device_path_hwmon=$(readlink -f "$hwmon_dir/device")
            if [[ "$device_path_hwmon" == *"$pci_id"* ]]; then
                if [ -f "$hwmon_dir/power1_average" ]; then
                    hwmon_path="$hwmon_dir"
                    break
                fi
            fi
        fi
    done

    if [ -n "$pci_id" ]; then
        local pci_id_segment_for_sensors=$(echo "$pci_id" | awk -F'[:.]' '{print $2 $3}')
        sensors_chip_name=$(sensors -u | awk -v pci_id_segment="${pci_id_segment_for_sensors}" '
            /^(amdgpu|nvidia|nvme|radeon)-pci-[0-9a-f]+/ {
                match($0, /^(amdgpu|nvidia|nvme|radeon)-pci-[0-9a-f]+/);
                chip_name_full = substr($0, RSTART, RLENGTH);
                extracted_pci_part = chip_name_full;
                sub(/^(amdgpu|nvidia|nvme|radeon)-pci-/, "", extracted_pci_part);
                if (extracted_pci_part == pci_id_segment) {
                    print chip_name_full; exit;
                }
            }' | tr -d '/')
    fi

    echo "$pci_id"
    echo "$drm_card_path"
    echo "$hwmon_path"
    echo "$gpu_name"
    echo "$sensors_chip_name"
    echo "$abs_device_path"
}

bytes_to_gib_floor() {
    local bytes="$1"
    echo "$((${bytes} / (1024 * 1024 * 1024)))"
}

readarray -t gpu_info_array < <(get_gpu_info)

PCI_ID="${gpu_info_array[0]}"
DRMCARD_PATH="${gpu_info_array[1]}"
HWMON_PATH="${gpu_info_array[2]}"
GPU_NAME="${gpu_info_array[3]}"
SENSORS_CHIP_NAME="${gpu_info_array[4]}"
ABS_DEVICE_PATH="${gpu_info_array[5]}"

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

temperature="N/A"
temperature_color="$GREY_HEX"
gpu_usage="N/A"
usage_color="$GREY_HEX"
wattage="N/A"
wattage_color="$GREY_HEX"
remaining_gib="N/A"
vram_color="$GREY_HEX"

if [ -n "$SENSORS_CHIP_NAME" ]; then
    temperature_raw=$(sensors "${SENSORS_CHIP_NAME}" | grep "edge" | awk '{print $2}' | cut -c2- | tr -d '\n' 2>/dev/null)
    if [ -n "$temperature_raw" ]; then
        temperature=${temperature_raw%.*}
        if (( temperature < 65 )); then temperature_color="$GREEN_HEX"; else temperature_color="$RED_HEX"; fi
    fi
fi

if [ -f "${ABS_DEVICE_PATH}/gpu_busy_percent" ]; then
    gpu_usage_raw=$(cat "${ABS_DEVICE_PATH}/gpu_busy_percent" | tr -d '\n' 2>/dev/null)
    if [ -n "$gpu_usage_raw" ]; then
        gpu_usage=$(printf "%d" "$gpu_usage_raw")
        if (( gpu_usage < 95 )); then usage_color="$GREEN_HEX"; else usage_color="$RED_HEX"; fi
    fi
fi

if [ -f "${HWMON_PATH}/power1_average" ]; then
    wattage_raw=$(cat "${HWMON_PATH}/power1_average" | tr -d '\n' 2>/dev/null)
    if [ -n "$wattage_raw" ]; then
        wattage=$((wattage_raw / 1000000))
        if (( wattage < 150 )); then wattage_color="$GREEN_HEX"; else wattage_color="$RED_HEX"; fi
    fi
fi

total_bytes=""
used_bytes=""
if [ -f "${ABS_DEVICE_PATH}/mem_info_vram_total" ]; then total_bytes=$(cat "${ABS_DEVICE_PATH}/mem_info_vram_total" 2>/dev/null); fi
if [ -f "${ABS_DEVICE_PATH}/mem_info_vram_used" ]; then used_bytes=$(cat "${ABS_DEVICE_PATH}/mem_info_vram_used" 2>/dev/null); fi

if [ -n "$total_bytes" ] && [ -n "$used_bytes" ]; then
    total_gib=$(bytes_to_gib_floor "$total_bytes")
    used_gib=$(bytes_to_gib_floor "$used_bytes")
    remaining_gib=$((total_gib - used_gib))
    if (( remaining_gib <= 4 )); then vram_color="$RED_HEX"; elif (( remaining_gib <= 8 )); then vram_color="$YELLOW_HEX"; else vram_color="$GREEN_HEX"; fi
fi

cat <<EOF > "$CACHE_FILE"
{
    "temperature": "${temperature}", "temperature_color": "${temperature_color}",
    "usage": "${gpu_usage}", "usage_color": "${usage_color}",
    "wattage": "${wattage}", "wattage_color": "${wattage_color}",
    "vram_free_gib": "${remaining_gib}", "vram_color": "${vram_color}"
}
EOF
