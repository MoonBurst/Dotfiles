#!/bin/bash
set -x # THIS LINE IS NOW UNCOMMENTED BY DEFAULT.
         # When you run the script, it will print each command as it's executed.
         # PLEASE COPY ALL OF THIS OUTPUT AND PASTE IT BACK TO ME.

# This script downloads chat logs from f-list.net for a specified date range
# and searches for specific strings within them.

# --- Configuration ---
BASE_URL="https://chat.f-list.net/adl"
LOG_FILE_NAME="equestria.txt"
SEARCH_STRINGS=("moonburst" "moon burst") # Strings to search for
SAVE_DIR="found_chat_logs" # Directory to save logs that contain matches
# --- End Configuration ---

# Function to display usage information
usage() {
    echo "Usage: $0 <start_date> <end_date>"
    echo "  <start_date>: The starting date in INSEE-MM-DD format (e.g., 2025-07-01)"
    echo "  <end_date>:   The ending date in INSEE-MM-DD format (e.g., 2025-07-07)"
    echo ""
    echo "Example: $0 2025-07-01 2025-07-07"
    exit 1
}

# Check if start and end dates are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    usage
fi

START_DATE_STR="$1"
END_DATE_STR="$2"

# --- IMPORTANT: Date Command Check ---
# The 'date -d' command is a GNU Coreutils extension and might not work
# on macOS by default. If you are on macOS, you might need to install
# GNU Coreutils (e.g., 'brew install coreutils') and then use 'gdate'
# instead of 'date' in the lines below.
# You can test your 'date' command directly in your terminal:
# date -d "2025-07-01" +%s
# If this gives an error, you likely need 'gdate'.
# --- End Date Command Check ---

# Convert dates to seconds since epoch for easier comparison and iteration
START_SECONDS=$(date -d "$START_DATE_STR" +%s)
END_SECONDS=$(date -d "$END_DATE_STR" +%s)

# Validate dates
if [ $? -ne 0 ]; then
    echo "Error: Invalid date format or 'date -d' command issue. Please use INSEE-MM-DD."
    echo "       See 'IMPORTANT: Date Command Check' in the script comments."
    usage
fi

if [ "$START_SECONDS" -gt "$END_SECONDS" ]; then
    echo "Error: Start date cannot be after end date."
    usage
fi

# Create the directory to save found logs if it doesn't exist
mkdir -p "$SAVE_DIR"

echo "Searching for '${SEARCH_STRINGS[*]}' in chat logs from $START_DATE_STR to $END_DATE_STR..."
echo "---------------------------------------------------------------------"

# Loop through each day from start date to end date
CURRENT_SECONDS="$START_SECONDS"
while [ "$CURRENT_SECONDS" -le "$END_SECONDS" ]
do
    CURRENT_DATE=$(date -d "@$CURRENT_SECONDS" +%Y-%m-%d)
    URL="${BASE_URL}/${CURRENT_DATE}/${LOG_FILE_NAME}"
    TEMP_FILE="temp_log_${CURRENT_DATE}.txt"
    SAVED_FILE="$SAVE_DIR/${LOG_FILE_NAME%.txt}_${CURRENT_DATE}.txt" # e.g., equestria_2025-07-07.txt

    # Download the log file
    # -s: Silent mode
    # -o: Write output to file
    # -w "%{http_code}": Get HTTP code
    HTTP_CODE=$(curl -s -o "$TEMP_FILE" -w "%{http_code}" "$URL")

    if [ "$HTTP_CODE" -eq 200 ]; then
        MATCH_FOUND_ON_DATE=false
        for SEARCH_STRING in "${SEARCH_STRINGS[@]}"; do
            # Use grep to find lines containing the search string (case-insensitive)
            # The '-i' flag handles all capitalizations (e.g., "Moonburst", "moonburst", "MOONBURST").
            # If matches are found, print the date and then the matching lines.
            if grep -i "$SEARCH_STRING" "$TEMP_FILE"; then
                if [ "$MATCH_FOUND_ON_DATE" = false ]; then
                    echo "--- Matches for $CURRENT_DATE ---" # Header for matches on this date
                    MATCH_FOUND_ON_DATE=true
                fi
                # Grep already prints the matching lines, so no extra echo needed here.
            fi
        done

        if [ "$MATCH_FOUND_ON_DATE" = true ]; then
            cp "$TEMP_FILE" "$SAVED_FILE"
            echo "  -> Log with matches saved to '$SAVED_FILE'"
        fi
    # Removed messages for 404/failed downloads to keep output focused on matches.
    fi

    # Always clean up the temporary file after processing
    rm -f "$TEMP_FILE"

    # Increment date by one day (86400 seconds in a day)
    CURRENT_SECONDS=$((CURRENT_SECONDS + 86400))
done

echo "---------------------------------------------------------------------"
echo "Search complete."

# --- CRITICAL TROUBLESHOOTING STEPS (Please follow carefully!) ---
# If you are still getting "while/then for dquote error" or similar,
# these steps are essential for diagnosis:

# 1.  **Run with Bash Explicitly and Copy FULL Output:**
#     Open your terminal and run the script like this:
#     `bash your_script_name.sh 2025-07-01 2025-07-07`
#     (Replace `your_script_name.sh` with the actual name you saved it as).
#     Since `set -x` is now enabled, you will see a lot of output.
#     **PLEASE COPY *ALL* OF THIS OUTPUT (including the error message and the `+` lines)**
#     and paste it back to me. This is the most important piece of information.

# 2.  **Check for Invisible Characters / Line Endings:**
#     Even if you think you've done this, it's worth re-checking.
#     In your terminal, navigate to the directory where your script is saved.
#     Run these commands and paste their output:
#     a) `cat -v your_script_name.sh`
#        (This command will show non-printable characters, like `^M` for Windows line endings).
#     b) `hexdump -C your_script_name.sh | head -n 5`
#        (This shows the raw bytes of the file. Look for `0d 0a` (CRLF) at the end of lines
#        instead of just `0a` (LF)).

# 3.  **Try `dos2unix` (Again):**
#     If you have `dos2unix` installed (e.g., `sudo apt-get install dos2unix` on Debian/Ubuntu,
#     or `brew install dos2unix` on macOS), run it on your script:
#     `dos2unix your_script_name.sh`
#     Then try running the script again (Step 1).

# 4.  **Manual Re-typing of Problematic Lines:**
#     If all else fails, open the script in a simple text editor (like `nano` or `vi` in terminal,
#     or Notepad++ on Windows, VS Code, etc.). Manually delete and re-type the lines around
#     the `while` loop (the `while [...]` line and the `do` line). Save the file carefully.
# --- End CRITICAL TROUBLESHOOTING STEPS ---
