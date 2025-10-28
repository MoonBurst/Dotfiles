#!/usr/bin/env bash

# --- Define Repository Paths ---
# SCRIPTS_REPO points to the .git directory of your home-based dotfiles repo (~/.git).
SCRIPTS_REPO="$HOME/.git"
NIXOS_REPO="$HOME/nixos-config/"
PUSH_BRANCH="main"

# --- List of directories and files to sync for the SCRIPTS_REPO ---
# These paths MUST be relative to $HOME (the GIT_WORK_TREE)
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


# ================================================================
# 1. Sync the Dotfiles Repository (located at ~/.git)
#    - Runs from ~ using the bare repository method.
# ================================================================

echo "================== Syncing Dotfiles Repo =================="

GIT_DIR_PATH="$SCRIPTS_REPO"

if [ ! -d "$GIT_DIR_PATH" ]; then
    echo "Error: Git repository not found at $SCRIPTS_REPO. Please ensure you have run 'git init --bare' inside ~."
else
    # --- Set up the bare repository environment ---
    export GIT_WORK_TREE="$HOME"
    export GIT_DIR="$GIT_DIR_PATH"
    
    # CRITICAL FIX: Ensure the bare repo knows not to track all files in the home dir
    git config status.showUntrackedFiles no

    echo "Staging files for bare repository..."

    # Loop through paths and add their contents (relative to $HOME)
    for RELATIVE_PATH in "${DIRECTORIES[@]}"; do
        FULL_PATH="$HOME/$RELATIVE_PATH"
        if [ -e "$FULL_PATH" ]; then
            # Add with force to ensure all contents are staged
            git add --force "$RELATIVE_PATH"
        else
            echo "Path $FULL_PATH does not exist, skipping..."
        fi
    done

    # --- Perform conditional commit/push ---
    
    # Check if any changes were successfully staged
    # Exit code 1 means there are changes (differences between index and HEAD)
    if ! git diff --quiet --exit-code --cached; then
        echo "Changes detected and staged. Committing..."
        
        # Commit the changes (output is visible)
        if git commit -m "Automated dotfiles sync: $(date)"; then
            echo "Changes committed. Pushing to GitHub..."
            
            # CRITICAL FIX: Explicitly push HEAD to the remote branch
            git push origin HEAD:"$PUSH_BRANCH"
        else
            echo "Commit failed. Please check for errors."
        fi
    else
        echo "No changes detected in dotfiles repo, skipping commit/push."
    fi

    # --- Clean up the environment variables ---
    unset GIT_WORK_TREE
    unset GIT_DIR
fi

# ================================================================
# 2. Sync the NixOS Config Repo
#    - Runs from ~ using a subshell to safely manage directory change.
# ================================================================

echo ""
echo "================== Syncing NixOS Config Repo =================="

# Use a subshell (parentheses) to perform operations in isolation.
(
    # Navigate to the NixOS configuration repository
    cd "$NIXOS_REPO" || { echo "Error: $NIXOS_REPO directory not found. Skipping NixOS sync."; exit 0; }

    # Stage all modified, deleted, and untracked files
    git add .

    # Perform conditional commit/push
    # Check if any changes were successfully staged
    if ! git diff --quiet --exit-code --cached; then
        echo "Changes detected and staged. Committing..."
        
        # Commit the changes (output is visible)
        if git commit -m "Automated NixOS sync: $(date)"; then
            echo "Changes committed. Pushing to GitHub..."
            
            # CRITICAL FIX: Explicitly push HEAD to the remote branch
            git push origin HEAD:"$PUSH_BRANCH"
        else
             echo "Commit failed. Please check for errors."
        fi
    else
        echo "No changes detected in NixOS repo, skipping commit/push."
    fi
)
# The subshell exits, leaving the current directory at ~

echo ""
echo "============== All synchronization tasks complete. =============="
