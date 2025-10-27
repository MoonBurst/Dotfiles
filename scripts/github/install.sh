#!/bin/bash
#
# GitHub Config Sync Script (Executable)
# Author: Gemini
#
# This script performs two main functions:
# 1. Clones the MoonBurst Dotfiles and NixOS configurations into source directories.
# 2. **After a second confirmation**, it executes system changes:
#    - Creates symbolic links for dotfiles (~/.config and ~/).
#    - Runs the 'sudo nixos-rebuild switch' command for NixOS configurations.
#
################################################################################

# --- Configuration (UPDATED PATHS) ---
DOTFILES_REPO="https://github.com/MoonBurst/Dotfiles.git"
NIXOS_CONFIG_REPO="https://github.com/MoonBurst/nixos-configs.git"

DOTFILES_DIR="$HOME/.dotfiles-moonburst"
NIXOS_CONFIG_DIR="$HOME/nixos-config"

# --- Status Flags ---
NIXOS_CLONED=false
DOTFILES_CLONED=false

# Function to get Y/N confirmation
get_confirmation() {
    local prompt_text=$1
    while true; do
        # Use bold red for critical prompts
        read -r -p "$(tput setaf 1)$(tput bold)$prompt_text (y/n): $(tput sgr0)" response
        case "$response" in
            [Yy]* ) return 0 ;; # Yes
            [Nn]* ) return 1 ;; # No
            * ) echo "Please answer y or n." ;;
        esac
    done
}

echo "Starting configuration synchronization..."

# --- 1. Clone Dotfiles Repository (Conditional) ---
echo ""
echo "#########################################################"
echo "### 1/2: Dotfiles Synchronization"
echo "#########################################################"

if get_confirmation "Do you want to sync/update your dotfiles source into $DOTFILES_DIR?"; then
    if [ -d "$DOTFILES_DIR" ]; then
        echo "Directory $DOTFILES_DIR already exists. Pulling latest changes."
        (cd "$DOTFILES_DIR" && git pull --ff-only) || { echo "Error pulling dotfiles. Exiting."; exit 1; }
    else
        echo "Cloning $DOTFILES_REPO into $DOTFILES_DIR"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || { echo "Error cloning dotfiles. Exiting."; exit 1; }
    fi
    DOTFILES_CLONED=true
else
    echo "Skipping dotfiles synchronization."
fi


# --- 2. Clone NixOS Config Repository (Conditional) ---
echo ""
echo "#########################################################"
echo "### 2/2: NixOS Configuration Synchronization"
echo "#########################################################"

if get_confirmation "Do you want to sync/update your NixOS configuration into $NIXOS_CONFIG_DIR?"; then
    if [ -d "$NIXOS_CONFIG_DIR" ]; then
        echo "Directory $NIXOS_CONFIG_DIR already exists. Pulling latest changes."
        (cd "$NIXOS_CONFIG_DIR" && git pull --ff-only) || { echo "Error pulling NixOS configs. Exiting."; exit 1; }
    else
        echo "Cloning $NIXOS_CONFIG_REPO into $NIXOS_CONFIG_DIR"
        git clone "$NIXOS_CONFIG_REPO" "$NIXOS_CONFIG_DIR" || { echo "Error cloning NixOS configs. Exiting."; exit 1; }
    fi
    NIXOS_CLONED=true
else
    echo "Skipping NixOS configuration synchronization."
fi

echo ""
echo "========================================================="
echo "✅ Configuration Sync Status"
echo "Dotfiles Source ($DOTFILES_DIR):    $(if $DOTFILES_CLONED; then echo "UPDATED/CLONED"; else echo "SKIPPED"; fi)"
echo "NixOS Config ($NIXOS_CONFIG_DIR): $(if $NIXOS_CLONED; then echo "UPDATED/CLONED"; else echo "SKIPPED"; fi)"
echo "========================================================="

echo ""
echo "### ⚠️ CRITICAL EXECUTION STEPS STARTING NOW ⚠️ ###"
echo ""

# --- STEP A: Dotfiles Application Execution (Symlinking) ---
if $DOTFILES_CLONED; then
    echo "--- ⚠️ STEP A: AUTOMATICALLY APPLYING DOTFILES (HIGH RISK) ⚠️ ---"
    echo "This step will create/overwrite symbolic links in your ~/.config and ~/ folders."
    if get_confirmation "Do you want to proceed with AUTOMATICALLY creating symlinks now?"; then
        echo "Creating symlinks for dotfiles (ln -sfv)..."
        (
            # Change directory to the source repo
            cd "$DOTFILES_DIR" || { echo "Failed to enter $DOTFILES_DIR for symlinking."; exit 1; }
            
            # Create ~/.config if it doesn't exist
            mkdir -p "$HOME/.config"

            # 1. Symlink top-level files to $HOME (e.g., .zshrc)
            echo "--> Symlinking top-level dotfiles (files starting with '.') to $HOME..."
            for item in .* ; do
                # Skip . and .. and any directories found
                if [[ "$item" == "." || "$item" == ".." || -d "$item" ]]; then
                    continue
                fi
                # Force symlink file from source to $HOME
                ln -sfv "$PWD/$item" "$HOME/$item"
            done

            # 2. Handle directories in the source repo that should go into ~/.config
            echo "--> Symlinking application directories to $HOME/.config/..."
            for item in * .*; do
                # Skip files, .git, . and ..
                if [[ ! -d "$item" || "$item" == "." || "$item" == ".." || "$item" == ".git" ]]; then
                    continue
                fi

                # Special case: If the directory is named .config, symlink its contents to $HOME/.config
                if [[ "$item" == ".config" ]]; then
                    echo "    - Found .config/ directory. Symlinking its contents to $HOME/.config/..."
                    
                    # Temporarily enable dotglob to find hidden files/dirs inside .config
                    shopt -s dotglob 
                    for content in .config/*; do
                        # Skip .config/. and .config/..
                        if [[ "$(basename "$content")" == "." || "$(basename "$content")" == ".." ]]; then
                            continue
                        fi
                        # Symlink the content (e.g., .config/alacritty) to ~/.config/alacritty
                        ln -sfv "$PWD/$content" "$HOME/.config/$(basename "$content")"
                    done
                    shopt -u dotglob # Turn it off
                    continue
                fi
                
                # General case: Symlink the whole directory (e.g., nvim, tmux) into ~/.config
                echo "    - Symlinking directory $item to $HOME/.config/$item"
                ln -sfv "$PWD/$item" "$HOME/.config/$item"
            done
            
            echo "Dotfiles symlinking finished. Check for errors above."
        )
        echo "Automatic Dotfiles application complete."
    else
        echo "Skipping automatic symlink creation for dotfiles."
    fi
else
    echo "--- STEP A: DOTFILES APPLICATION SKIPPED (Cloning was skipped) ---"
fi


# --- STEP B: NixOS Application Execution (Rebuild) ---
if $NIXOS_CLONED; then
    echo ""
    echo "--- ⚠️ STEP B: RUNNING NIXOS-REBUILD SWITCH (EXTREME DANGER) ⚠️ ---"
    echo "WARNING: This command requires 'sudo' and can potentially break your system."
    echo "Ensure that the configuration in $NIXOS_CONFIG_DIR is safe for your hardware."
    if get_confirmation "Do you want to run 'sudo nixos-rebuild switch --flake $NIXOS_CONFIG_DIR' NOW?"; then
        echo "Executing NixOS rebuild..."
        # Execute the command
        sudo nixos-rebuild switch --flake "$NIXOS_CONFIG_DIR"
        
        if [ $? -eq 0 ]; then
            echo "NixOS rebuild finished successfully."
        else
            echo "$(tput setaf 1)$(tput bold)NixOS rebuild failed. Check the error output above.$(tput sgr0)"
        fi
    else
        echo "Skipping automatic NixOS rebuild."
    fi
else
    echo "--- STEP B: NIXOS APPLICATION SKIPPED (Cloning was skipped) ---"
fi

echo ""
echo "Script execution finished."
