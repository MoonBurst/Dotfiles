#!/usr/bin/env bash


git add .config/dunst/
git add .config/geany/colorschemes/
git add .config/hypr/
git add .config/MangoHud/
git add .config/rofi/
git add .config/swayidle/
git add .config/waybar/

if [[ -n $(git status -s) ]]; then
    echo "Changes found. Pushing changes..."
    git add -A && git commit -m 'update' && git push
else
    echo "No changes found. Skip pushing."
fi
