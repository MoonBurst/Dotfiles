#!/bin/bash

# Check if the input file is provided
if [ -z "$1" ]; then
  echo "Please provide the input GIF file as an argument."
  exit 1
fi

# Check if ImageMagick is installed
command -v convert >/dev/null 2>&1 || { echo >&2 "ImageMagick is required but not installed. Aborting."; exit 1; }

# Get the directory and filename of the input GIF
input_dir=$(dirname "$1")
input_filename=$(basename "$1")

# Resize the GIF to 800x800
convert "$1" -resize 200x200 "$input_dir/resized.gif"

# Extract frames from the resized GIF
cd "$input_dir"
convert resized.gif -crop 100x100+0+0 +repage corner1.gif
convert resized.gif -crop 100x100+100+0 +repage corner2.gif
convert resized.gif -crop 100x100+0+100 +repage corner3.gif
convert resized.gif -crop 100x100+100+100 +repage corner4.gif

echo "GIF corners extracted successfully."
