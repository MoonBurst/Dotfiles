#!/usr/bin/env bash


# Define a temporary file path
TEMP_FILE=$(mktemp --suffix=.png)

# 1. Capture the selected region and save it to the temporary file
# The -g "$(slurp -d)" part waits for user selection.
grim -g "$(slurp -d)" -t png "$TEMP_FILE"

# Check if grim succeeded (i.e., if the user didn't cancel the selection)
if [ -f "$TEMP_FILE" ]; then
    # 2. Process the temporary file with satty and save to the final location
    satty -f "$TEMP_FILE" -o ~/Screenshots/"$(date +%Y-%m-%d_%H:%M:%S.png)" --save-after-copy

    # 3. Clean up the temporary file
    rm "$TEMP_FILE"
fi
