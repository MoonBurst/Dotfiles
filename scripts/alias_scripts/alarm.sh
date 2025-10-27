#!/usr/bin/env bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: alarm <timer> <message>"
    exit 1
fi

# Get the timer and message from arguments
timer="$1"
message="$2"

# Initialize seconds variable
seconds=0

# Parse the timer input for hours, minutes, and seconds
while [[ $timer =~ ([0-9]+)([hms]) ]]; do
    num=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}
    case "$unit" in
        h) seconds=$((seconds + num * 3600)) ;;  # Convert hours to seconds
        m) seconds=$((seconds + num * 60)) ;;    # Convert minutes to seconds
        s) seconds=$((seconds + num)) ;;          # Seconds
    esac
    timer=${timer/${BASH_REMATCH[0]}/}  # Remove the matched part from the timer
done

# Check if any time was added
if [ $seconds -eq 0 ]; then
    echo "Invalid timer format. Use <number>h (for hours), <number>m (for minutes), or <number>s (for seconds)."
    exit 1
fi

# Function to stop the audio
stop_audio() {
    pkill -f "play ~/Documents/communicator.mp3"  # Kill the audio playback process
}

# Set trap to call stop_audio on script exit
trap stop_audio EXIT

# Countdown loop
while [ $seconds -gt 0 ]; do
    echo -ne "Time left: $((seconds / 3600))h $(( (seconds % 3600) / 60 ))m $((seconds % 60))s\r"
    sleep 1
    seconds=$((seconds - 1))
done

# Send notification and play the audio
notify-send "Alarm" "$message"
play ~/Documents/communicator.mp3
