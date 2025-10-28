#!/usr/bin/env bash

SCRIPTS_REPO="$HOME/.git"
NIXOS_REPO="$HOME/nixos-config/"
PUSH_BRANCH="main"

DIRECTORIES=(
  "scripts/"
  ".config/dunst/"
  ".config/fastfetch/"
  ".config/hypr/"
  ".config/MangoHud/"
  ".config/fuzzel/"
  ".config/sway/"
  ".config/swayidle/"
  ".config/waybar/"
  ".config/Trolltech.conf"
  ".config/satty/"
  ".config/sherlock/"
  ".config/zsh/"
  ".config/kitty/"
  ".local/share/gtk-2.0/"
  ".local/share/gtk-3.0/"
  ".local/share/gtk-4.0/"
  ".local/share/themes/"
  ".local/share/icons/"
)


echo "================== Syncing Dotfiles Repo =================="

GIT_DIR_PATH="$SCRIPTS_REPO"

if [ ! -d "$GIT_DIR_PATH" ]; then
    echo "Error: Git repository not found at $SCRIPTS_REPO. Please ensure you have run 'git init --bare' inside ~."
else
    export GIT_WORK_TREE="$HOME"
    export GIT_DIR="$GIT_DIR_PATH"
    
    echo "Staging files for bare repository..."
    STAGED_ANYTHING=false
    for RELATIVE_PATH in "${DIRECTORIES[@]}"; do
        FULL_PATH="$HOME/$RELATIVE_PATH"
        if [ -e "$FULL_PATH" ]; then
            git add --force "$RELATIVE_PATH"
            STAGED_ANYTHING=true
        else
            echo "Path $FULL_PATH does not exist, skipping..."
        fi
    done

    if git diff --quiet --exit-code --cached; then
        echo "No changes detected in dotfiles repo, skipping commit/push."
    else
        echo "Changes detected and staged. Committing..."
        if git commit -m "Automated dotfiles sync: $(date)" > /dev/null 2>&1; then
            echo "Changes committed. Pushing to GitHub..."
            git push origin "$PUSH_BRANCH"
        fi
    fi

    unset GIT_WORK_TREE
    unset GIT_DIR
fi

echo ""
echo "================== Syncing NixOS Config Repo =================="

(
    cd "$NIXOS_REPO" || { echo "Error: $NIXOS_REPO directory not found. Skipping NixOS sync."; exit 0; }

    git add .
    
    if git diff --quiet --exit-code --cached; then
        echo "No changes detected in NixOS repo, skipping commit/push."
    else
        echo "Changes detected and staged. Committing..."
        if git commit -m "Automated NixOS sync: $(date)" > /dev/null 2>&1; then
            echo "Changes committed. Pushing to GitHub..."
            git push origin "$PUSH_BRANCH"
        fi
    fi
)

echo ""
echo "============== All synchronization tasks complete. =============="
