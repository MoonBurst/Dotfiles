#!/bin/bash

# This script is designed to be called from a file manager's context menu.
# It creates a .desktop file for the selected executable or script.

# --- Configuration ---
# The directory where the .desktop files will be saved.
# ~/.local/share/applications/ is the standard location for user-specific launchers.
OUTPUT_DIR="$HOME/.local/share/applications"

# --- Check for selected file/directory ---
# In most file managers (Nautilus, Thunar, Dolphin), the selected path is passed as the first argument ($1).
if [ -z "$1" ]; then
    # Use zenity for a graphical error message if available, otherwise fallback to echo.
    if command -v zenity &> /dev/null; then
        zenity --error --title="Error" --text="No file or directory selected. Please right-click on a file/executable."
    else
        echo "Error: No file or directory selected. Please right-click on a file/executable." >&2
    fi
    exit 1
fi

SELECTED_PATH="$1"

# Resolve the absolute path of the selected item
# This handles cases where the script is called from a different directory
ABSOLUTE_PATH=$(realpath "$SELECTED_PATH")

# --- Extract Name and Filename ---
# Get the base name (e.g., "my_script.sh" from "/home/user/my_script.sh")
BASE_NAME=$(basename "$ABSOLUTE_PATH")

# Derive a user-friendly name (e.g., "My Script" from "my_script.sh")
# Capitalize first letter, replace underscores/hyphens with spaces, remove file extension
DISPLAY_NAME=$(echo "$BASE_NAME" | sed 's/\([a-z]\)/\U\1/;s/[_-]/ /g;s/\.[^.]*$//')

# Sanitize the display name for the .desktop filename
# Convert spaces to hyphens, lowercase, remove non-alphanumeric characters except hyphens and periods
FILENAME=$(echo "$DISPLAY_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]')
DESKTOP_FILENAME="${FILENAME}.desktop"

# --- Construct the .desktop file content ---
# Default values for the .desktop entry
DESKTOP_NAME="$DISPLAY_NAME"
DESKTOP_COMMENT="Launcher for $BASE_NAME"
DESKTOP_EXEC="$ABSOLUTE_PATH"
DESKTOP_ICON="" # You can set a generic icon path here, e.g., "utilities-terminal" or leave blank
DESKTOP_TERMINAL="false" # Set to 'true' if the application runs in a terminal (e.g., a simple bash script)
DESKTOP_TYPE="Application"
DESKTOP_CATEGORIES="" # Optional, e.g., "Utility;Development;"

# --- Optional: Prompt for Terminal setting (using zenity) ---
# This makes the script more interactive. If zenity is not installed, it will default to false.
if command -v zenity &> /dev/null; then
    if zenity --question --title="Launcher Options" --text="Does this application need to run in a terminal?"; then
        DESKTOP_TERMINAL="true"
    fi
fi

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Assemble the .desktop file content
DESKTOP_FILE_CONTENT="[Desktop Entry]
Name=$DESKTOP_NAME
Comment=$DESKTOP_COMMENT
Exec=$DESKTOP_EXEC
Icon=$DESKTOP_ICON
Terminal=$DESKTOP_TERMINAL
Type=$DESKTOP_TYPE
Categories=$DESKTOP_CATEGORIES
"

# Remove empty lines for optional fields if they are not set
DESKTOP_FILE_CONTENT=$(echo "$DESKTOP_FILE_CONTENT" | sed '/^Icon=$/d' | sed '/^Categories=$/d')

# --- Write the .desktop file ---
OUTPUT_PATH="${OUTPUT_DIR}/${DESKTOP_FILENAME}"
echo "$DESKTOP_FILE_CONTENT" > "$OUTPUT_PATH"

# --- Set executable permissions (important for .desktop files) ---
chmod +x "$OUTPUT_PATH"

# --- Notification ---
if command -v notify-send &> /dev/null; then
    notify-send "Desktop Launcher Created" "Successfully created '$DESKTOP_NAME' launcher at $OUTPUT_PATH" -i "$DESKTOP_ICON"
elif command -v zenity &> /dev/null; then
    zenity --info --title="Success" --text="Successfully created '$DESKTOP_NAME' launcher at:\n$OUTPUT_PATH\n\nYou may need to log out and back in, or refresh your desktop environment, for the new entry to appear."
else
    echo "Successfully created .desktop file:"
    echo "  Path: $OUTPUT_PATH"
    echo "  Content:"
    echo "---"
    echo "$DESKTOP_FILE_CONTENT"
    echo "---"
    echo "You may need to log out and back in, or refresh your desktop environment, for the new entry to appear."
fi

exit 0
