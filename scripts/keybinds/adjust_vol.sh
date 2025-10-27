#!/usr/bin/env bash

# Function to check the default audio sink and adjust the volume accordingly
check_and_set_volume() {
    local pipewire_status=$(wpctl status) # Retrieve the PipeWire status

    # Extract the default sink line marked with '*'
    local default_sink_line=$(echo "$pipewire_status" | grep -E "\s+\*\s+.*")
    echo "DEBUG: Default sink line -> $default_sink_line" # Debugging output

    # Extract the default sink's ID (the number following the '*' marker)
    local sink_id=$(echo "$default_sink_line" | awk '{print $3}')
    echo "DEBUG: Default sink ID -> $sink_id" # Debugging output

    # Extract the default sink's name for verification
    local default_sink_name=$(echo "$default_sink_line" | awk '{for (i=4; i<=NF; i++) printf $i " "; print ""}' | xargs)
    echo "DEBUG: Default sink name -> $default_sink_name" # Debugging output

    # Check if the default sink is Navi 31
    if echo "$default_sink_name" | grep -q "Navi 31 HDMI/DP Audio Digital Stereo (HDMI 2)"; then
        echo "Default audio sink is Navi 31. Adjusting volume to limit 0.35..."
        wpctl set-volume "$sink_id" 5%+ --limit 0.50

    # Check if the default sink is Fiio E10 Analog Stereo
    elif echo "$default_sink_name" | grep -q "Fiio E10 Analog Stereo"; then
        echo "Default audio sink is Fiio E10 Analog Stereo. Adjusting volume to limit 0.70..."
        wpctl set-volume "$sink_id" 5%+ --limit 0.70

    else
        echo "Default audio sink is not Navi 31 or Fiio E10. No changes made."
    fi
}

# Call the function
check_and_set_volume
