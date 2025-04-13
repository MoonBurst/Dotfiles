#!/bin/bash

# Path for JSON metadata
JSON_DIR="$HOME/.config/sherlock/json"
mkdir -p "$JSON_DIR"

# Initialize an empty JSON array
json_array="["

# Process clipboard entries
cliphist list | while read -r line; do
    if [[ "$line" == *"��"* ]]; then
        # Check if the line contains binary data (possible image)
        id=$(echo "$line" | awk -F '\t' '{print $1}')
        if [[ -n "$id" ]]; then
            # Decode the binary data
            decoded_output=$(cliphist decode "$id" 2>/dev/null)

            if [[ -n "$decoded_output" ]]; then
                # Add decoded binary data as base64-encoded string
                binary_data=$(echo "$decoded_output" | base64)

                # Format as a JSON object
                json_array+="{
                    \"title\": \"Clipboard Entry $id\",
                    \"result\": \"Processed result for entry $id\",
                    \"binary\": \"$binary_data\"
                },"
            fi
        fi
    else
        # Add entries without binary data
        json_array+="{
            \"title\": \"$line\",
            \"result\": \"$line\"
        },"
    fi
done

# Remove the trailing comma from the JSON array
json_array=${json_array%,}

# Close the JSON array
json_array+="]"

# Save the JSON to a file
echo "$json_array" > "$JSON_DIR/output.json"

# Print the JSON
cat "$JSON_DIR/output.json"
