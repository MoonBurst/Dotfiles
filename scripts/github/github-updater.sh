#!/bin/bash

# List of directories and files to sync
DIRECTORIES=(
  "$HOME/scripts/"
  "$HOME/.config/dunst/"
  "$HOME/.config/hypr/"
  "$HOME/.config/MangoHud/"
  "$HOME/.config/fuzzel/"
  "$HOME/.config/sway/"
  "$HOME/.config/swayidle/"
  "$HOME/.config/waybar/"
  "$HOME/.config/Trolltech.conf"
  "$HOME/.config/satty/"
  "$HOME/.zshrc"
)

# Navigate to the repository root
cd "$HOME/scripts/" || { echo "Error: ~/scripts/ directory not found"; exit 1; }

# Loop through directories and files to add them
for DIR in "${DIRECTORIES[@]}"; do
  if [ -e "$DIR" ]; then  # Check if the path exists
    echo "Adding: $DIR"
    git add --force "$DIR"
  else
    echo "Path $DIR does not exist, skipping..."
  fi
done

# Commit changes with a timestamp
git commit -m "Automated sync: $(date)"

# Push changes to GitHub
git push origin main
