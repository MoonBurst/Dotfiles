#!/bin/bash

filename="$1"
size="$2"

if [ -z "$filename" ] || [ -z "$size" ]; then
  echo "Usage: $0 <filename> <WxH>"
  exit 1
fi

output_filename="${filename%.*}_${size}.${filename##*.}"
magick "$filename" -resize "${size}!" "$output_filename"
echo "Resized '$filename' to ${size} and saved as '$output_filename'"
