#!/bin/bash

# A lightweight script to check Pacman and AUR updates and output clean JSON.
# Requires 'pacman-contrib' and 'paru'.

# Regex to strip ALL ANSI escape codes (color/bold/etc.)
# This is more effective than relying on --nocolor flags.
ANSI_STRIP_REGEX="s/\x1b\[[0-9;]*m//g"

# --- Functions to get and clean the lists ---

# Function to get Pacman updates and clean the output
get_pacman_updates() {
    # checkupdates output: package-name current-version -> new-version
    checkupdates | sed -E "$ANSI_STRIP_REGEX" | awk '{print $1}'
}

# Function to get AUR updates and clean the output
get_aur_updates() {
    # Using 'paru -Qua' to get AUR updates
    paru -Qua 2>/dev/null | sed -E "$ANSI_STRIP_REGEX" | awk '{print $1}'
}


# --- Main Logic ---

PACMAN_LIST=$(get_pacman_updates)
AUR_LIST=$(get_aur_updates)

# Calculate counts (handling empty list case)
PACMAN_COUNT=$(echo "$PACMAN_LIST" | awk 'NF' | wc -l)
AUR_COUNT=$(echo "$AUR_LIST" | awk 'NF' | wc -l)

TOTAL_COUNT=$((PACMAN_COUNT + AUR_COUNT))

# --- Tooltip Formatting ---

TOOLTIP_CONTENT=""

if [[ "$PACMAN_COUNT" -gt 0 ]]; then
    TOOLTIP_CONTENT+="Repo Updates ($PACMAN_COUNT):\n"
    TOOLTIP_CONTENT+="$PACMAN_LIST\n"
fi

if [[ "$AUR_COUNT" -gt 0 ]]; then
    if [[ -n "$TOOLTIP_CONTENT" ]]; then
        TOOLTIP_CONTENT+="\n" # Add an extra newline between sections
    fi
    TOOLTIP_CONTENT+="AUR Updates ($AUR_COUNT):\n"
    TOOLTIP_CONTENT+="$AUR_LIST"
fi

# Replace all real newlines with the escaped character '\n' for JSON.
CLEAN_TOOLTIP=$(echo -e "$TOOLTIP_CONTENT" | sed ':a;N;$!ba;s/\n/\\n/g')


# --- JSON Output ---

if [[ "$TOTAL_COUNT" -gt 0 ]]; then
    echo "{\"text\":\"$TOTAL_COUNT\", \"tooltip\":\"$CLEAN_TOOLTIP\", \"class\":\"has-updates\"}"
else
    # Always output a valid JSON object to avoid the Waybar JSON parsing error.
    echo "{\"text\":\"0\", \"tooltip\":\"System is up to date.\", \"class\":\"updated\"}"
fi
