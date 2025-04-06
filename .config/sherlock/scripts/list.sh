#!/bin/bash

# Paths for Sherlock integration
ICON_DIR="$HOME/.config/sherlock/icons"
JSON_DIR="$HOME/.config/sherlock/json"
mkdir -p "$ICON_DIR" "$JSON_DIR"

# Function to process valid clipboard entries
process_entry() {
    local index="$1"

    # Decode binary data to a temporary file
    cliphist decode "$index" > /tmp/original_image_${index}.png

    # Check if the decoded file is a valid PNG
    if file /tmp/original_image_${index}.png | grep -q "PNG image"; then
        # Create thumbnail only if it doesn't already exist
        if [[ ! -f "$ICON_DIR/thumbnail_${index}.png" ]]; then
            magick /tmp/original_image_${index}.png -resize 128x128 "$ICON_DIR/thumbnail_${index}.png"
        fi

        # Generate JSON for Sherlock
        cat << EOF > "$JSON_DIR/output_${index}.json"
{
    "title": "Clipboard Entry $index",
    "description": "Binary data and thumbnail for entry $index.",
    "icon": "$ICON_DIR/thumbnail_${index}.png",
    "result": "Processed result for entry $index.",
    "method": "cliphist decode",
    "field": "clipboard"
}
EOF
        echo "$index"  # Output numeric ID to stdout
    else
        echo "Entry $index does not contain a valid image. Skipping." >&2
    fi

    # Clean up temporary files
    rm -f /tmp/original_image_${index}.png
}

# Main loop to process valid clipboard entries
cliphist list | while read -r line; do
    if echo "$line" | grep -q "binary data"; then
        index=$(echo "$line" | awk '{print $1}')
        if [[ "$index" =~ ^[0-9]+$ ]]; then
            process_entry "$index"
        else
            echo "Skipping line with invalid ID: $line" >&2
        fi
    else
        echo "Skipping line without binary data: $line" >&2
    fi
done
