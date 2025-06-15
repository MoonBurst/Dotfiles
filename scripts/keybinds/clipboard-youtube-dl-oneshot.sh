#!/bin/bash

# Configuration
BASE_DOWNLOAD_DIR="$HOME/Music//Music.lossless/Music/000 MP3s need updated" # Top-level directory for all downloads
LOG_FILE="$HOME/Music/youtube-music-hotkey.log" # Log file for debugging/notifications
AUDIO_EXT="mp3" # The target audio extension (matches --audio-format)

# Ensure jq is installed for robust JSON parsing
if ! command -v jq &> /dev/null; then
    notify-send "YouTube Music Downloader Error" "jq command not found. Please install 'jq' for reliable info extraction. Script exiting."
    echo "$(date): Error: 'jq' command not found. Please install it." >> "$LOG_FILE"
    exit 1
fi

# Determine clipboard command based on display server
if [ -n "$WAYLAND_DISPLAY" ]; then
    CLIPBOARD_COMMAND="wl-paste"
else
    CLIPBOARD_COMMAND="xclip -o -selection clipboard"
fi

# Ensure base download directory exists
mkdir -p "$BASE_DOWNLOAD_DIR"

# Get URL from clipboard
URL=$($CLIPBOARD_COMMAND)

# Basic URL validation
if [[ ! "$URL" =~ ^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/ ]]; then
    notify-send "Download Error" "No valid YouTube URL found in clipboard."
    echo "$(date): No valid YouTube URL found in clipboard: $URL" >> "$LOG_FILE"
    exit 1
fi

# --- Extract Title and Channel/Artist for Notification ---
SONG_INFO_JSON=$(yt-dlp --print-json --no-warnings --no-playlist "$URL" 2>/dev/null)

EXTRACTED_TITLE=""
EXTRACTED_CHANNEL=""
NOTIFY_MESSAGE_PREVIEW=""

if [ -n "$SONG_INFO_JSON" ]; then
    EXTRACTED_TITLE=$(echo "$SONG_INFO_JSON" | jq -r '.title // empty')
    EXTRACTED_CHANNEL=$(echo "$SONG_INFO_JSON" | jq -r '.channel // empty')
    
    # Fallback for notification if title/channel are empty or null
    if [ -z "$EXTRACTED_CHANNEL" ]; then EXTRACTED_CHANNEL="Unknown Artist"; fi
    if [ -z "$EXTRACTED_TITLE" ]; then EXTRACTED_TITLE=$(echo "$URL" | cut -c 1-50); fi

    NOTIFY_MESSAGE_PREVIEW="$EXTRACTED_TITLE by $EXTRACTED_CHANNEL"
else
    NOTIFY_MESSAGE_PREVIEW="Starting download for: $(echo "$URL" | cut -c 1-50)..."
    echo "$(date): Failed to extract song info for $URL, using URL in notification." >> "$LOG_FILE"
fi

# --- Predict the final filename using the desired template (now confirmed byte-perfect) ---
PREDICTED_FILE_PATH=$(yt-dlp --get-filename \
                              -o "$BASE_DOWNLOAD_DIR/%(channel)s/%(title)s.$AUDIO_EXT" \
                              --no-warnings --no-playlist "$URL" 2>/dev/null)


# --- Check if the predicted file already exists ---
if [ -f "$PREDICTED_FILE_PATH" ]; then
    notify-send "Already Downlaoded" "Already downloaded: $EXTRACTED_TITLE by $EXTRACTED_CHANNEL"
    echo "$(date): Already downloaded: $PREDICTED_FILE_PATH for URL: $URL" >> "$LOG_FILE"
    exit 0
fi

# --- Proceed with Download if not found ---
notify-send "Starting Download" "$NOTIFY_MESSAGE_PREVIEW"

echo "--- Download started at $(date) for: $URL ---" >> "$LOG_FILE"

# Download the highest quality audio as MP3
yt-dlp -x --audio-format "$AUDIO_EXT" --audio-quality 0 --embed-metadata --add-metadata \
       -o "$BASE_DOWNLOAD_DIR/%(channel)s/%(title)s.%(ext)s" "$URL" >> "$LOG_FILE" 2>&1

# --- Post-Download Notifications ---
if [ $? -eq 0 ]; then
    notify-send "Download Complete" " $EXTRACTED_TITLE by $EXTRACTED_CHANNEL"
    echo "$(date): Download successful for: $URL" >> "$LOG_FILE"
else
    notify-send "Download FAILED" "Download failed for URL: $(echo "$URL" | cut -c 1-50)... Check $LOG_FILE"
    echo "$(date): Download failed for: $URL" >> "$LOG_FILE"
fi
