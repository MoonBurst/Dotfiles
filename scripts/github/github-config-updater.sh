#!/usr/bin/env bash

git pull

git add scripts/

git add .config/dunst/
git add .config/hypr/
git add .config/MangoHud/
git add .config/rofi/
git add .config/swayidle/
git add .config/waybar/

if [[ -n $(git status -s) ]]; then
    echo "Changes found. Pushing changes..."
     git commit -m 'update' && git push
else
    echo "No changes found. Skip pushing."
fi
