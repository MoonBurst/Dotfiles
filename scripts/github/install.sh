#!/bin/bash
#
# Custom Installation Script for MoonBurst/Dotfiles
# This script executes a specific sequence of download, extraction, and move operations.
#
# ASSUMPTION: This script is intended to be run on a fresh Linux install where
#             .config, .local, and scripts folders in the home directory do not yet exist,
#             allowing for simple 'mv' operations instead of complex 'rsync' merging.

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

echo "--- Custom Dotfiles Setup for ${REPO_USER}/${REPO_NAME} ---"

# 1. Download the repository archive
echo "[1/5] Downloading archive from GitHub..."
mkdir -p "$DOWNLOAD_DEST"
# Use curl to download the zip file to a temporary location
curl -L -o "$TEMP_ARCHIVE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download archive using curl. Exiting."
    exit 1
fi

# New Error Check: Verify file size is large enough to be a valid ZIP
ARCHIVE_SIZE=$(stat -c%s "$TEMP_ARCHIVE" 2>/dev/null || echo 0)
MIN_SIZE=1000 # Minimum expected size for a tiny ZIP file (1KB)

if [ "$ARCHIVE_SIZE" -lt "$MIN_SIZE" ]; then
    echo "Error: Download failed! The downloaded file is only ${ARCHIVE_SIZE} bytes (expected a ZIP file > ${MIN_SIZE} bytes)."
    echo "Action required: Please verify that the GitHub URL is correct and public: ${DOWNLOAD_URL}"
    # If not in dry run, attempt cleanup anyway
    if [ -z "$DRY_RUN" ]; then rm -f "$TEMP_ARCHIVE"; fi
    exit 1
fi

# 2. Extract to ~/github_download/
echo "[2/5] Extracting archive contents to $DOWNLOAD_DEST..."
# Ensure the destination folder is clean before extraction (runs even in dry-run to stage extraction)
rm -rf "${EXTRACTED_FOLDER}"
unzip -q "$TEMP_ARCHIVE" -d "$DOWNLOAD_DEST"

# 3. Move .config, .local, and scripts folders to ~/
echo "[3/5] Moving specified folders to $HOME..."

# Check if the extracted directory exists
if [ ! -d "$EXTRACTED_FOLDER" ]; then
    echo "Error: Extraction failed or folder structure unexpected. Expected: ${EXTRACTED_FOLDER}. Exiting."
    # If not in dry run, attempt cleanup anyway
    if [ -z "$DRY_RUN" ]; then rm -f "$TEMP_ARCHIVE"; fi
    exit 1
fi

# Move .config
if [ -d "${EXTRACTED_FOLDER}/.config" ]; then
    echo "-> Moving .config/ to $HOME"
    if [ -z "$DRY_RUN" ]; then
        mv "${EXTRACTED_FOLDER}/.config" "$HOME/"
    else
        echo "   [DRY-RUN] mv \"${EXTRACTED_FOLDER}/.config\" \"$HOME/\""
    fi
fi

# Move .local
if [ -d "${EXTRACTED_FOLDER}/.local" ]; then
    echo "-> Moving .local/ to $HOME"
    if [ -z "$DRY_RUN" ]; then
        mv "${EXTRACTED_FOLDER}/.local" "$HOME/"
    else
        echo "   [DRY-RUN] mv \"${EXTRACTED_FOLDER}/.local\" \"$HOME/\""
    fi
fi

# Move scripts
if [ -d "${EXTRACTED_FOLDER}/scripts" ]; then
    echo "-> Moving scripts/ to $HOME"
    if [ -z "$DRY_RUN" ]; then
        mv "${EXTRACTED_FOLDER}/scripts" "$HOME/"
    else
        echo "   [DRY-RUN] mv \"${EXTRACTED_FOLDER}/scripts\" \"$HOME/\""
    fi
fi

# 4. Create the symbolic link for .zshenv
# The .zshenv file remains in the extracted folder after the folder moves above.
ZSHENV_SOURCE="${EXTRACTED_FOLDER}/.zshenv"
ZSHENV_TARGET="$HOME/.zshenv"

echo "[4/5] Creating symbolic link: $ZSHENV_TARGET -> $ZSHENV_SOURCE"
if [ -f "$ZSHENV_SOURCE" ]; then
    if [ -z "$DRY_RUN" ]; then
        # -s: symbolic link, -f: force (overwrite existing link/file), -n: treat link as file if target is directory
        ln -sfn "$ZSHENV_SOURCE" "$ZSHENV_TARGET"
        echo "-> Link created successfully."
    else
        echo "   [DRY-RUN] ln -sfn \"$ZSHENV_SOURCE\" \"$ZSHENV_TARGET\""
        echo "-> Link command printed (Dry Run)."
    fi
else
    echo "Warning: .zshenv not found at $ZSHENV_SOURCE. Link not created."
fi

# 5. Final Cleanup
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
echo "Link created: $ZSHENV_TARGET"
#
