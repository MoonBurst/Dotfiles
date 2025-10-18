#!/bin/bash

LOGO_DIR="${HOME}/.config/fastfetch"
if [ ! -d "$LOGO_DIR" ]; then
    echo "Error: Logo directory not found: $LOGO_DIR"
    exit 1
fi
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
    -iname "*.svg"
)

ALL_LOGOS_RAW=$(find "$LOGO_DIR" -type f \( "${FIND_NAME_ARGS[@]}" \))

if [ -z "$ALL_LOGOS_RAW" ]; then
    echo "Error: No suitable logo images found in $LOGO_DIR"
    exit 1
fi

IFS=$'\n' read -r -d '' -a AVAILABLE_LOGOS <<< "$ALL_LOGOS_RAW"

if ! command -v shuf &> /dev/null
then
    echo "Warning: 'shuf' command not found. Cannot pick a random logo. Using the first found logo."
    RANDOM_LOGO="${AVAILABLE_LOGOS[0]}"
else
    RANDOM_LOGO=$(printf "%s\n" "${AVAILABLE_LOGOS[@]}" | shuf -n 1)
fi

if [ -z "$RANDOM_LOGO" ]; then
    echo "Error: Could not pick a random logo. Exiting."
    exit 1
fi




LOGO_FILENAME=$(basename "$RANDOM_LOGO")
FASTFETCH_COMMAND="fastfetch"
DEFAULT_LOGO_WIDTH=27
#DEFAULT_LOGO_HEIGHT=10
DEFAULT_KEY_TYPE="string"
DEFAULT_LOGO_PADDING_RIGHT=2 
DEFAULT_LOGO_PADDING_TOP=1   



CURRENT_LOGO_WIDTH="$DEFAULT_LOGO_WIDTH"
CURRENT_LOGO_HEIGHT="$DEFAULT_LOGO_HEIGHT"
CURRENT_KEY_TYPE="$DEFAULT_KEY_TYPE"
CURRENT_LOGO_PADDING_RIGHT="$DEFAULT_LOGO_PADDING_RIGHT"
CURRENT_LOGO_PADDING_TOP="$DEFAULT_LOGO_PADDING_TOP" 


QUOTED_LOGO_PATH=$(printf "%q" "$RANDOM_LOGO")

$FASTFETCH_COMMAND \
    --logo "$QUOTED_LOGO_PATH" \
    --logo-width "$CURRENT_LOGO_WIDTH" \
    --logo-height "$CURRENT_LOGO_HEIGHT" \
    --key-type "$CURRENT_KEY_TYPE" \
    --logo-padding-right "$CURRENT_LOGO_PADDING_RIGHT" \
    --logo-padding-top "$CURRENT_LOGO_PADDING_TOP" 
