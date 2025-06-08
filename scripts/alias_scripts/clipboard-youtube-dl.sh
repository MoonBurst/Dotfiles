#!/bin/bash

# Configuration
BASE_DOWNLOAD_DIR="$HOME/Music/YouTube Downloads" # Top-level directory for all downloads
LOG_FILE="$HOME/.local/share/youtube-music-autodl.log" # Log file for debugging/notifications
AUDIO_EXT="mp3" # The target audio extension (matches --audio-format)
SLEEP_INTERVAL=2 # How often (in seconds) to check the clipboard

# Ensure jq is installed for robust JSON parsing
if ! command -v jq &> /dev/null; then
    notify-send "YouTube Music Downloader Error" "jq command not found. Please install 'jq' for reliable info extraction. Script exiting."
    echo "$(date): Error: 'jq' command not found. Please install it." >> "$LOG_FILE"
    exit 1
fi

# Determine clipboard command based on display server
CLIPBOARD_COMMAND=""
if [ -n "$WAYLAND_DISPLAY" ]; then
    if command -v wl-paste &> /dev/null; then
        CLIPBOARD_COMMAND="wl-paste"
    else
        notify-send "YouTube Music Downloader Error" "wl-paste not found for Wayland. Install 'wl-clipboard'."
        echo "$(date): Error: wl-paste not found for Wayland. Install 'wl-clipboard'." >> "$LOG_FILE"
        exit 1
    fi
else
    if command -v xclip &> /dev/null; then
        CLIPBOARD_COMMAND="xclip -o -selection clipboard"
    else
        notify-send "YouTube Music Downloader Error" "xclip not found for X11. Install 'xclip'."
        echo "$(date): Error: xclip not found for X11. Install 'xclip'." >> "$LOG_FILE"
        exit 1
    fi
fi

# Ensure base download directory exists
mkdir -p "$BASE_DOWNLOAD_DIR"

# Initial notification
notify-send "YouTube Music Downloader" "Monitoring clipboard for YouTube music links..."
echo "--- Script started at $(date) ---" >> "$LOG_FILE"
echo "Monitoring clipboard for YouTube music links... (Downloads to: $BASE_DOWNLOAD_DIR)" >> "$LOG_FILE"

PREVIOUS_URL="" # Variable to store the last processed URL

# --- Main monitoring loop ---
while true; do
    CURRENT_URL=$($CLIPBOARD_COMMAND)

    # Only process if clipboard content is a new, valid YouTube URL
    if [[ "$CURRENT_URL" =~ ^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/ ]] && [ "$CURRENT_URL" != "$PREVIOUS_URL" ]; then
        echo "$(date): Detected new YouTube URL: $CURRENT_URL" >> "$LOG_FILE"

        # --- Get Song Info and Predict File Path in One yt-dlp Call ---
        # NOTE: We are now redirecting stderr to a *different* file (stderr.log)
        # to ensure stdout only contains the expected JSON and filename.
        YT_DLP_OUTPUT=$(yt-dlp --print-json \
                               --get-filename \
                               -o "$BASE_DOWNLOAD_DIR/%(channel)s/%(title)s.%(ext)s" \
                               --audio-format "$AUDIO_EXT" \
                               --no-warnings --no-playlist "$CURRENT_URL" 2> "$HOME/.local/share/yt-dlp_stderr.log")

        # --- DEBUGGING: Log raw yt-dlp output to a temp file for inspection ---
        echo "$YT_DLP_OUTPUT" > /tmp/yt_dlp_raw_output_debug.log
        echo "$(date): Raw yt-dlp output saved to /tmp/yt_dlp_raw_output_debug.log" >> "$LOG_FILE"
        
        # Extract predicted path (it's the last line of --get-filename output)
        PREDICTED_FILE_PATH=$(echo "$YT_DLP_OUTPUT" | tail -n 1)

        # Extract JSON metadata
        # We need to check if YT_DLP_OUTPUT contains at least two lines for head/tail to work correctly.
        # If it's a single line (just a filename, no JSON), or empty, this will cause issues.
        # A more robust check might be needed here, but for now, let's see the raw output.
        SONG_INFO_JSON=$(echo "$YT_DLP_OUTPUT" | head -n -1)

        # --- DEBUGGING: Log extracted info and predicted path ---
        echo "$(date): Predicted File Path from tail: \"$PREDICTED_FILE_PATH\"" >> "$LOG_FILE"
        echo "$(date): JSON content extracted for jq: \"$SONG_INFO_JSON\"" >> "$LOG_FILE" # Log the content jq receives!

        EXTRACTED_TITLE=$(echo "$SONG_INFO_JSON" | jq -r '.title // empty')
    
        # Handle jq error specifically for channel
        EXTRACTED_CHANNEL=$(echo "$SONG_INFO_JSON" | jq -r '.channel // empty' 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "$(date): JQ failed to parse channel from JSON. JSON was: $SONG_INFO_JSON" >> "$LOG_FILE"
            EXTRACTED_CHANNEL="Unknown Artist (JQ error)"
        fi
        
        # Fallback for notification if title/channel are empty or null
        if [ -z "$EXTRACTED_CHANNEL" ] || [ "$EXTRACTED_CHANNEL" = "null" ]; then EXTRACTED_CHANNEL="Unknown Artist"; fi
        if [ -z "$EXTRACTED_TITLE" ] || [ "$EXTRACTED_TITLE" = "null" ]; then EXTRACTED_TITLE=$(echo "$CURRENT_URL" | cut -c 1-50); fi

        NOTIFY_MESSAGE_PREVIEW="$EXTRACTED_TITLE by $EXTRACTED_CHANNEL"

        # --- DEBUGGING: Log final extracted info ---
        echo "$(date): Final Extracted Title: \"$EXTRACTED_TITLE\"" >> "$LOG_FILE"
        echo "$(date): Final Extracted Channel: \"$EXTRACTED_CHANNEL\"" >> "$LOG_FILE"

        # --- Check if the predicted file already exists ---
        if [ -f "$PREDICTED_FILE_PATH" ]; then
            notify-send "Already Downloaded" "Already downloaded: $EXTRACTED_TITLE by $EXTRACTED_CHANNEL"
            echo "$(date): Already downloaded: $PREDICTED_FILE_PATH for URL: $CURRENT_URL" >> "$LOG_FILE"
        else
            # --- Proceed with Download if not found ---
            notify-send "Starting Download" "$NOTIFY_MESSAGE_PREVIEW"
            echo "--- Download started at $(date) for: $CURRENT_URL ---" >> "$LOG_FILE"

            # Download the highest quality audio as MP3
            yt-dlp -x --audio-format "$AUDIO_EXT" --audio-quality 0 --embed-metadata --add-metadata \
                   -o "$BASE_DOWNLOAD_DIR/%(channel)s/%(title)s.%(ext)s" "$CURRENT_URL" >> "$LOG_FILE" 2>&1

            # --- Post-Download Notifications ---
            if [ $? -eq 0 ]; then
                notify-send "Download Complete" "$EXTRACTED_TITLE by $EXTRACTED_CHANNEL"
                echo "$(date): Download successful for: $CURRENT_URL" >> "$LOG_FILE"
            else
                notify-send "Download FAILED" "Download failed for: $(echo "$CURRENT_URL" | cut -c 1-50)... Check $LOG_FILE"
                echo "$(date): Download failed for: $CURRENT_URL" >> "$LOG_FILE"
            fi
        fi

        PREVIOUS_URL="$CURRENT_URL" # Update last processed URL
    fi

    sleep "$SLEEP_INTERVAL" # Wait before checking clipboard again
done
