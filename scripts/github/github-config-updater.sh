#!/bin/bash

# List of directories to sync
DIRECTORIES=(
  "$HOME/scripts/"
  "$HOME/.config/dunst/"
  "$HOME/.config/hypr/"
  "$HOME/.config/MangoHud/"
  "$HOME/.config/fuzzel/"
  "$HOME/.config/sway/"
  "$HOME/.config/swayidle/"
  "$HOME/.config/waybar/"
)

# Navigate to the repository root (assume it's still in ~/scripts/)
cd "$HOME/scripts/" || { echo "Error: ~/scripts/ directory not found"; exit 1; }

# Loop through directories and ensure all files, including ignored ones, are staged
for DIR in "${DIRECTORIES[@]}"; do
  if [ -d "$DIR" ]; then
    echo "Adding directory: $DIR"
    git add --force "$DIR"
  else
    echo "Directory $DIR does not exist, skipping..."
  fi
done

# Additional check for MangoHud.conf
if [ -f "$HOME/.config/MangoHud/MangoHud.conf" ]; then
  git add --force "$HOME/.config/MangoHud/MangoHud.conf"
  echo "Added: $HOME/.config/MangoHud/MangoHud.conf"
else
  echo "MangoHud.conf not found in $HOME/.config/MangoHud/"
fi

# Commit changes with a timestamp message
git commit -m "Automated sync: $(date)"

# Push changes to GitHub
git push origin main
