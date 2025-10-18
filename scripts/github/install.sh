#!/bin/bash
#
# Custom Installation Script for MoonBurst/Dotfiles
# This script executes a specific sequence of download, extraction, and move operations.


# Check for Dry Run mode
DRY_RUN=""
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN="true"
    echo "--- !!! RUNNING IN DRY-RUN MODE !!! ---"
    echo "NO files will be moved, linked, or deleted. Commands will only be printed."
    echo "----------------------------------------"
fi

# --- Configuration ---
REPO_USER="MoonBurst"
REPO_NAME="Dotfiles"
BRANCH="main" # Assuming the default branch is 'main'
DOWNLOAD_URL="https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.zip"
DOWNLOAD_DEST="$HOME/github_download"
TEMP_ARCHIVE="/tmp/${REPO_NAME}_${BRANCH}.zip"
# The folder created when unzipping a GitHub archive (e.g., Dotfiles-main)
EXTRACTED_FOLDER="${DOWNLOAD_DEST}/${REPO_NAME}-${BRANCH}"

# --- Confirmation Step (DEMAND 'confirm') ---
if [ -z "$DRY_RUN" ]; then
    # Define ANSI Codes
    RED='\033[31m'
    BLUE='\033[34m'
    BOLD='\033[1m'
    RESET='\033[0m'
    
    # 1. Print the warning/prompt message with colors using echo -e
    echo -e "${RED}${BOLD}WARNING:${RESET} This will ${RED}overwrite${RESET} .config and .local/share to match that of ${BLUE}Moon Burst${RESET}."
    
    # 2. Get user input, explicitly asking for "confirm"
    read -r -p "To proceed, please type 'confirm': " response
    
    case "$response" in
        [cC][oO][nN][fF][iI][rR][mM]) # Checks for 'confirm' (case-insensitive)
            echo "Proceeding with installation..."
            ;;
        *)
            echo "Installation aborted by user."
            exit 0
            ;;
    esac
fi
# ------------------------------------

echo "--- Custom Dotfiles Setup for ${REPO_USER}/${REPO_NAME} ---"

# 1. Download the repository archive (unchanged)
echo "[1/5] Downloading archive from GitHub..."
mkdir -p "$DOWNLOAD_DEST"
# Use curl to download the zip file to a temporary location
curl -L -o "$TEMP_ARCHIVE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download archive using curl. Exiting."
    exit 1
fi

# Error Check: Verify file size is large enough to be a valid ZIP
ARCHIVE_SIZE=$(stat -c%s "$TEMP_ARCHIVE" 2>/dev/null || echo 0)
MIN_SIZE=1000 # Minimum expected size for a tiny ZIP file (1KB)

if [ "$ARCHIVE_SIZE" -lt "$MIN_SIZE" ]; then
    echo "Error: Download failed! The downloaded file is only ${ARCHIVE_SIZE} bytes (expected a ZIP file > ${MIN_SIZE} bytes)."
    echo "Action required: Please verify that the GitHub URL is correct and public: ${DOWNLOAD_URL}"
    # If not in dry run, attempt cleanup anyway
    if [ -z "$DRY_RUN" ]; then rm -f "$TEMP_ARCHIVE"; fi
    exit 1
fi

# 2. Extract to ~/github_download/ (unchanged)
echo "[2/5] Extracting archive contents to $DOWNLOAD_DEST..."
# Ensure the destination folder is clean before extraction (runs even in dry-run to stage extraction)
rm -rf "${EXTRACTED_FOLDER}"
unzip -q "$TEMP_ARCHIVE" -d "$DOWNLOAD_DEST"

# Check if the extracted directory exists
if [ ! -d "$EXTRACTED_FOLDER" ]; then
    echo "Error: Extraction failed or folder structure unexpected. Expected: ${EXTRACTED_FOLDER}. Exiting."
    # If not in dry run, attempt cleanup anyway
    if [ -z "$DRY_RUN" ]; then rm -f "$TEMP_ARCHIVE"; fi
    exit 1
fi

# 3. Move .config, .local, and scripts folders to ~/ (unchanged)
echo "[3/5] Moving specified folders to $HOME..."

# Move .config contents
if [ -d "${EXTRACTED_FOLDER}/.config" ]; then
    echo "-> Moving contents of .config/ to $HOME/.config"
    if [ -z "$DRY_RUN" ]; then
        mkdir -p "$HOME/.config" # Ensure destination exists
        mv "${EXTRACTED_FOLDER}/.config/"* "$HOME/.config/"
    else
        echo "   [DRY-RUN] mkdir -p \"$HOME/.config\""
        echo "   [DRY-RUN] mv \"${EXTRACTED_FOLDER}/.config/\"* \"$HOME/.config/\""
    fi
fi

# Move .local contents
if [ -d "${EXTRACTED_FOLDER}/.local" ]; then
    echo "-> Moving contents of .local/ to $HOME/.local"
    if [ -z "$DRY_RUN" ]; then
        mkdir -p "$HOME/.local" # Ensure destination exists
        mv "${EXTRACTED_FOLDER}/.local/"* "$HOME/.local/"
    else
        echo "   [DRY-RUN] mkdir -p \"$HOME/.local\""
        echo "   [DRY-RUN] mv \"${EXTRACTED_FOLDER}/.local/\"* \"$HOME/.local/\""
    fi
fi

# Move scripts contents
if [ -d "${EXTRACTED_FOLDER}/scripts" ]; then
    echo "-> Moving contents of scripts/ to $HOME/scripts"
    if [ -z "$DRY_RUN" ]; then
        mkdir -p "$HOME/scripts" # Ensure destination exists
        mv "${EXTRACTED_FOLDER}/scripts/"* "$HOME/scripts/"
    else
        echo "   [DRY-RUN] mkdir -p \"$HOME/scripts\""
        echo "   [DRY-RUN] mv \"${EXTRACTED_FOLDER}/scripts/\"* \"$HOME/scripts/\""
    fi
fi

# 4. MOVE the .zshenv file (FIXED: Changed from ln -sfn to mv)
ZSHENV_SOURCE="${EXTRACTED_FOLDER}/.zshenv"
ZSHENV_TARGET="$HOME/.zshenv"

echo "[4/5] Moving .zshenv to $HOME/.zshenv (Prevents broken symlink cleanup issue)"
if [ -f "$ZSHENV_SOURCE" ]; then
    if [ -z "$DRY_RUN" ]; then
        # Use mv to move the file directly so cleanup doesn't break the configuration
        mv "$ZSHENV_SOURCE" "$ZSHENV_TARGET"
        echo "-> .zshenv moved successfully."
    else
        echo "   [DRY-RUN] mv \"$ZSHENV_SOURCE\" \"$ZSHENV_TARGET\""
        echo "-> Move command printed (Dry Run)."
    fi
else
    echo "Warning: .zshenv not found at $ZSHENV_SOURCE. File not moved."
fi

# 5. Final Cleanup (unchanged, but now safe)
echo "[5/5] Performing cleanup..."

if [ -z "$DRY_RUN" ]; then
    rm -f "$TEMP_ARCHIVE"
    # Remove the empty download directory after files have been moved out
    rm -rf "$DOWNLOAD_DEST"
    echo "-> Cleanup completed (Files deleted)."
else
    echo "   [DRY-RUN] rm -f \"$TEMP_ARCHIVE\""
    echo "   [DRY-RUN] rm -rf \"$DOWNLOAD_DEST\""
    echo "-> Cleanup commands printed (Files preserved for inspection in $DOWNLOAD_DEST)."
fi

echo ""
echo "--- Installation Complete! ---"
echo "Folders moved: .config, .local, scripts"
echo "File moved: $ZSHENV_TARGET"
