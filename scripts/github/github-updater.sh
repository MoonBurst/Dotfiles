#!/bin/bash

# --- Crontab Backup ---
# Define the temporary location for the crontab backup as requested.
CRON_TMP_DIR="/tmp/crontab/"
CRON_TMP_FILE="$CRON_TMP_DIR/cron"

echo "Creating temporary crontab backup at $CRON_TMP_FILE"
mkdir -p "$CRON_TMP_DIR"
# List the crontab and save it to the dedicated temporary file
crontab -l > "$CRON_TMP_FILE"

# --- List of directories and files to sync ---
DIRECTORIES=(
  "$CRON_TMP_DIR"
  "$HOME/scripts/"
  "$HOME/.config/dunst/"
  "$HOME/.config/fastfetch/"
  "$HOME/.config/hypr/"
  "$HOME/.config/MangoHud/"
  "$HOME/.config/fuzzel/"
  "$HOME/.config/sway/"
  "$HOME/.config/swayidle/"
  "$HOME/.config/waybar/"
  "$HOME/.config/Trolltech.conf"
  "$HOME/.config/satty/"
  "$HOME/.config/sherlock/"
  "$HOME/.config/zsh/"
  "$HOME/.config/kitty/"
  "$HOME/.local/share/gtk-2.0/"
  "$HOME/.local/share/gtk-3.0/"
  "$HOME/.local/share/gtk-4.0/"
  "$HOME/.local/share/themes/"
  "$HOME/.local/share/icons/"
)

# Navigate to the repository root
cd "$HOME/scripts/" || { echo "Error: ~/scripts/ directory not found"; exit 1; }

# Loop through directories and files to add them
for DIR in "${DIRECTORIES[@]}"; do
  if [ -e "$DIR" ]; then  # Check if the path exists
    echo "Adding: $DIR"
    # Use --force to ensure files outside the repo's working tree are added
    git add --force "$DIR"
  else
    echo "Path $DIR does not exist, skipping..."
  fi
done

# Commit changes with a timestamp
git commit -m "Automated sync: $(date)"

# Push changes to GitHub
echo "Pushing changes to GitHub..."
git push origin main
echo "Sync complete."
