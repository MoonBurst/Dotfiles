#!/bin/bash

# Get the sink ID for the specified application dynamically
get_sink_id() {
    app_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')  # Convert input to lowercase
    sink_id=$(pactl list sink-inputs | grep -B 20 -i "application.name = \"$app_name\"" | grep -oP 'Sink Input #\K\d+')
    echo $sink_id
}

# Define the function to raise the volume
raise_volume() {
    pactl set-sink-input-volume $1 +10%
}

# Define the function to lower the volume
lower_volume() {
    pactl set-sink-input-volume $1 -10%
}

# Check if the application name and action are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 [application_name] [raise | lower]"
    exit 1
fi

app_name=$1
action=$2

sink_id=$(get_sink_id "$app_name")

# Check if the sink ID is retrieved successfully
if [ -z "$sink_id" ]; then
    echo "Error: Sink ID not found for application: $app_name. Make sure the application is running."
    exit 1
fi

# Main script logic to handle volume adjustment
case "$action" in
    "raise" | "RAISE" | "Raise")
        raise_volume $sink_id
        echo "Volume raised for $app_name."
        ;;
    "lower" | "LOWER" | "Lower")
        lower_volume $sink_id
        echo "Volume lowered for $app_name."
        ;;
    *)
        echo "Usage: $0 [application_name] [raise | lower]"
        ;;
esac
