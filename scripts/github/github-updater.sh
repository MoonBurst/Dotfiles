#!/usr/bin/env bash

# --- Define Repository Paths ---
# SCRIPTS_REPO now points to the correct location for a home-directory-based bare repo.
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
#    This section operates without changing the current directory (~).
# ================================================================

echo "================== Syncing Dotfiles Repo =================="

GIT_DIR_PATH="$SCRIPTS_REPO"

# Check if the repository exists (the ~/.git folder)
if [ ! -d "$GIT_DIR_PATH" ]; then
    echo "Error: Git repository not found at $SCRIPTS_REPO. Please ensure you have run 'git init --bare' inside ~."
    # If the dotfiles repo doesn't exist, we skip this section but continue to NixOS sync.
else

    # --- Set up the bare repository environment ---
    # This configuration makes Git look for the .git folder in $HOME/.git, 
    # and manages files across the entire $HOME directory.
    export GIT_WORK_TREE="$HOME"
    export GIT_DIR="$GIT_DIR_PATH"

    # Loop through external paths and force-add their contents (relative to $HOME)
    for RELATIVE_PATH in "${DIRECTORIES[@]}"; do
        FULL_PATH="$HOME/$RELATIVE_PATH"
        if [ -e "$FULL_PATH" ]; then
            echo "Adding: $FULL_PATH"
            git add --force "$RELATIVE_PATH"
        else
            echo "Path $FULL_PATH does not exist, skipping..."
        fi
    done

    # --- Perform conditional commit/push ---
    if git diff --cached --quiet; then
        echo "No changes detected in dotfiles repo, skipping commit/push."
    else
        git commit -m "Automated sync: $(date)"
        echo "Pushing changes for dotfiles repo to GitHub..."
        git push origin "$PUSH_BRANCH"
    fi

    # --- Clean up the environment variables ---
    unset GIT_WORK_TREE
    unset GIT_DIR
fi

# ================================================================
# 2. Sync the NixOS Config Repo
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
    if git diff --cached --quiet; then
        echo "No changes detected in NixOS repo, skipping commit/push."
    else
        git commit -m "Automated NixOS sync: $(date)"
        echo "Pushing changes for NixOS repo to GitHub..."
        git push origin "$PUSH_BRANCH"
    fi
) 
# The subshell automatically returns the current directory to what it was before (~).

echo ""
echo "============== All synchronization tasks complete. =============="
