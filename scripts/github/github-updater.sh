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

    # CRITICAL FIX: Ensure the bare repo configuration is active for this session.
    # This prevents Git from thinking every single file in $HOME is untracked.
    git config status.showUntrackedFiles no 
    
    echo "Staging files for bare repository..."
    
    # Stage all files listed in DIRECTORIES
    for RELATIVE_PATH in "${DIRECTORIES[@]}"; do
        FULL_PATH="$HOME/$RELATIVE_PATH"
        if [ -e "$FULL_PATH" ]; then
            git add --force "$RELATIVE_PATH"
        else
            # Path skipping messages are already logged in previous runs, keeping log clean here.
            :
        fi
    done

    # --- New Logic: Check if anything was actually staged ---
    # git diff --quiet --exit-code --cached checks if the index (staged area) differs from HEAD.
    if git diff --quiet --exit-code --cached; then
        echo "No changes detected in dotfiles repo, skipping commit/push."
    else
        echo "Changes detected and staged. Committing..."
        # We rely on the staged check above, so we can commit directly
        if git commit -m "Automated dotfiles sync: $(date)"; then
            echo "Changes committed. Pushing to GitHub..."
            # Note: We do not pipe output to /dev/null on commit so we can see what was committed.
            git push origin "$PUSH_BRANCH"
        else
            echo "Error during commit. Check staged files manually."
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
        # Removed piping to /dev/null so you can see commit details if successful
        if git commit -m "Automated NixOS sync: $(date)"; then
            echo "Changes committed. Pushing to GitHub..."
            git push origin "$PUSH_BRANCH"
        fi
    fi
)

echo ""
echo "============== All synchronization tasks complete. =============="
