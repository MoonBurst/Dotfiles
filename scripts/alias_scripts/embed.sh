#!/usr/bin/env bash

# --- Input Validation ---

# Check if there is at least one argument
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <image_file> <file1> [file2] [file3] ..."
    echo "Example: $0 my_photo.jpg secret_note.txt audio.mp3"
    exit 1
fi

# The first argument is the image file
image_file="$1"

# Check if the image file exists and is a regular file
if [ ! -f "$image_file" ]; then
    echo "Error: Image file '$image_file' not found or is not a regular file."
    exit 1
fi

# All other arguments are the files to be archived
files_to_archive=("${@:2}")

# Check if all files to be archived exist
for file in "${files_to_archive[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: File to archive '$file' not found or is not a regular file."
        exit 1
    fi
done

# --- Archiving Section ---

# Create a temporary ZIP file name
zip_file="temp_archive.zip"

echo "Creating ZIP file..."
zip -q "$zip_file" "${files_to_archive[@]}"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create the ZIP file. Exiting."
    rm -f "$zip_file"
    exit 1
fi

# --- Embedding Section ---

# Get the filename and extension to create the new output file name
filename=$(basename -- "$image_file")
extension="${filename##*.}"
filename_no_ext="${filename%.*}"
output_file="${filename_no_ext}-with-archive.${extension}"

echo "Embedding the ZIP file into the image..."
cat "$image_file" "$zip_file" > "$output_file"

if [ $? -ne 0 ]; then
    echo "Error: Failed to embed the ZIP file. Exiting."
    rm -f "$zip_file"
    exit 1
fi

# --- Cleanup ---

echo "Cleaning up temporary files..."
rm -f "$zip_file"

echo "Success! The new file is '$output_file'."
echo "To extract the files, use a command like 'unzip $output_file'."
