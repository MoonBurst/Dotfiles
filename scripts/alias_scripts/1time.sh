#!/usr/bin/env bash

# This script runs 'nix-shell -p' and automatically runs the first package
# if no explicit --run argument is provided.

set -e

# Set the temporary XDG variables for this specific execution.
XDG_CACHE_HOME="/tmp/nix-1time-cache"
XDG_CONFIG_HOME="/tmp/nix-1time-config"

# Check if the user only provided a package name (the first argument).
if [ $# -eq 1 ]; then
    PACKAGE_NAME="$1"
    
    # Inject '-p' flag and a '--run' command to execute the package immediately.
    # Example: '1time thunar' becomes 'nix-shell -p thunar --run "thunar"'
    exec nix-shell -p "$PACKAGE_NAME" --run "$PACKAGE_NAME"
else
    # If the user provided more arguments (e.g., '1time thunar --run "thunar &"'), 
    # just inject '-p' and pass everything else through.
    exec nix-shell -p "$@"
fi
