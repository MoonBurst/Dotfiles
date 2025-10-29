#!/run/current-system/sw/bin/bash

# Define Waybar base directory
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"

# --- 1. Find Waybar Executable Path ---
WAYBAR_EXEC_PATH=$(which waybar)

if [ -z "${WAYBAR_EXEC_PATH}" ]; then
    echo "ERROR: Waybar executable not found using 'which waybar'. Ensure Waybar is installed."
    exit 1
fi
echo "INFO: Waybar executable found at: ${WAYBAR_EXEC_PATH}"

# --- 2. Determine Config & Style Paths ---
CURRENT_HOST=$(hostname -s)

# WAYBAR_CONFIG_FILE: The main config file is now named after the hostname (e.g., moonbeauty.json)
WAYBAR_CONFIG_FILE="${WAYBAR_CONFIG_DIR}/${CURRENT_HOST}"

# WAYBAR_STYLE: The style file is always named 'style.css'
WAYBAR_STYLE="style.css"
WAYBAR_STYLE_PATH="${WAYBAR_CONFIG_DIR}/${WAYBAR_STYLE}"

echo "--- Waybar Config Loader Started ---"
echo "User: $(whoami) | Host: ${CURRENT_HOST}"
echo "Will attempt to use Config File: ${WAYBAR_CONFIG_FILE}"

# --- 3. Configuration Validation and Override (Optional) ---
# Check if the host-specific JSON config exists. 
# We can use a companion file (e.g., moonbeauty.conf) to override variables
# if needed, otherwise we rely on the host-specific JSON file directly.

HOST_OVERRIDE_FILE="${WAYBAR_CONFIG_DIR}/${CURRENT_HOST}.conf"

if [ -f "${HOST_OVERRIDE_FILE}" ]; then
    echo "  INFO: Found host-specific override file. Sourcing it now."
    source "${HOST_OVERRIDE_FILE}"
    # This lets you override WAYBAR_CONFIG_FILE or WAYBAR_STYLE if needed
fi

# --- 4. Final Path Checks ---

if [ ! -f "${WAYBAR_CONFIG_FILE}" ]; then
    echo "ERROR: Main Waybar config file NOT FOUND at: ${WAYBAR_CONFIG_FILE}"
    echo "Please create this JSON file with your Waybar module definitions."
    exit 1
fi

if [ ! -f "${WAYBAR_STYLE_PATH}" ]; then
    echo "WARNING: Style file NOT FOUND at: ${WAYBAR_STYLE_PATH}"
    echo "Waybar will launch, but styling may be broken."
fi

# --- 5. Waybar Execution ---

echo "--- Config setup complete. Executing Waybar... ---"

# Kill any existing Waybar instances
if pgrep -x "waybar" > /dev/null; then
    echo "Waybar is already running. Killing existing instance(s)..."
    pkill waybar
    sleep 0.5 
fi

# Launch Waybar using the dynamically determined path and files
# NOTE: The -c argument uses the host-specific JSON config file.
# The -s argument uses the single, global style.css file.
"${WAYBAR_EXEC_PATH}" -c "${WAYBAR_CONFIG_FILE}" -s "${WAYBAR_STYLE_PATH}" & 

echo "Waybar launched in the background."
echo "--- Waybar Config Loader Finished ---"
