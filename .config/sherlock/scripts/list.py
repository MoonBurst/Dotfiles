#!/usr/bin/env python3
import subprocess
import os
from PIL import Image

def get_cliphist_list():
    """Retrieve clipboard history using cliphist."""
    result = subprocess.run(['cliphist', 'list'], stdout=subprocess.PIPE, text=True)
    return result.stdout.splitlines()

def find_image_ids(entries):
    """Filter clipboard entries and extract IDs for binary image data."""
    image_ids = []
    for entry in entries:
        if "binary data" in entry.lower() and ("png" in entry.lower() or "jpg" in entry.lower()):
            entry_id = entry.split("\t")[0].strip()  # Extract the numeric ID
            image_ids.append(entry_id)
    return image_ids

def decode_entries(image_ids, output_dir):
    """Decode all image entries and save them as files in the output directory."""
    os.makedirs(output_dir, exist_ok=True)
    image_paths = []

    for image_id in image_ids:
        filename = os.path.join(output_dir, f"decoded_image_{image_id}.png")
        with open(filename, "wb") as file:
            result = subprocess.run(['cliphist', 'decode', image_id], stdout=subprocess.PIPE)
            file.write(result.stdout)
        image_paths.append(filename)

    return image_paths

def validate_image(file_path):
    """Check if the file is a valid image."""
    try:
        with Image.open(file_path) as img:
            img.verify()  # Verify the image file
        return True
    except Exception:
        return False

def generate_thumbnails(image_paths, thumbnail_dir):
    """Generate thumbnails for the decoded images."""
    os.makedirs(thumbnail_dir, exist_ok=True)
    thumbnail_paths = []

    for image_path in image_paths:
        if validate_image(image_path):
            try:
                with Image.open(image_path) as img:
                    img.thumbnail((128, 128))  # Set thumbnail size (128x128)
                    thumbnail_path = os.path.join(thumbnail_dir, f"thumbnail_{os.path.basename(image_path)}")
                    img.save(thumbnail_path)
                    thumbnail_paths.append(thumbnail_path)
            except Exception as e:
                print(f"Error generating thumbnail for {image_path}: {e}")
        else:
            print(f"Skipping invalid image file: {image_path}")

    return thumbnail_paths

def process_with_sherlock(image_paths):
    """Pass all decoded image files to Sherlock in a single batch."""
    try:
        result = subprocess.run(['sherlock'] + image_paths, stdout=subprocess.PIPE, text=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running Sherlock: {e}")
        return ""

def process_images():
    """Main function to process image IDs, generate thumbnails, and pass them through Sherlock."""
    entries = get_cliphist_list()
    image_ids = find_image_ids(entries)

    if not image_ids:
        print("No image-related clipboard entries found.")
        return

    # Decode entries into an output directory
    output_dir = "decoded_images"
    image_paths = decode_entries(image_ids, output_dir)

    # Generate thumbnails
    thumbnail_dir = "thumbnails"
    thumbnails = generate_thumbnails(image_paths, thumbnail_dir)
    print(f"Thumbnails generated: {thumbnails}")

    # Process all images with Sherlock (optional step)
    sherlock_output = process_with_sherlock(image_paths)
    subprocess.run(['wl-copy'], input=sherlock_output, text=True)
    print("Processed images successfully. Output copied to clipboard.")

if __name__ == "__main__":
    process_images()
