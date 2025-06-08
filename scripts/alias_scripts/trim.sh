#!/bin/bash

LOGO_DIR="/home/moonburst/.config/fastfetch"

# Image file extensions to look for (case-insensitive)
FIND_NAME_ARGS=(
    -iname "*.jpg"
    -o
    -iname "*.jpeg"
    -o
    -iname "*.png"
    -o
    -iname "*.gif"
    -o
    -iname "*.bmp"
    -o
    -iname "*.svg" # SVG trimming might behave differently as it's vector-based
)

echo "Starting transparent edge trimming for images in: $LOGO_DIR"
echo "------------------------------------------------------"

# 1. Check if the logo directory exists
if [ ! -d "$LOGO_DIR" ]; then
    echo "Error: Logo directory not found: $LOGO_DIR"
    echo "Please ensure the directory exists and you have permissions to access it."
    exit 1
fi

# 2. Check if ImageMagick's 'convert' command is available
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick 'convert' command not found."
    echo "Please install ImageMagick (e.g., sudo apt install imagemagick)."
    exit 1
fi

# 3. Process each image file by piping find's output directly to the while loop
# This avoids the intermediate variable and the null byte warning.
find "$LOGO_DIR" -type f \( "${FIND_NAME_ARGS[@]}" \) -print0 | \
while IFS= read -r -d $'\0' image_file; do
    # Skip if the found item is not a regular file (e.g., a directory named like an image)
    # This is an extra safeguard, though -type f in find already handles most cases.
    if [ ! -f "$image_file" ]; then
        continue
    fi

    echo "Processing: $(basename "$image_file")"
    
    # Attempt to trim the image
    convert "$image_file" -trim +repage "$image_file"

    if [ $? -eq 0 ]; then
        echo "  -> Trimmed successfully."
    else
        echo "  -> Failed to trim (Error $?). Check image file integrity or permissions."
    fi
    echo "------------------------------------------------------"
done

echo "Transparent edge trimming complete."
