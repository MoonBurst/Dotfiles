nix-temp-run() {
    if [ "$#" -eq 0 ]; then
        echo "Usage: nix-temp-run <command> [args...]"
        return 1
    fi

    # 1. Create temporary directories in RAM (typically /tmp)
    local TEMP_HOME
    TEMP_HOME=$(mktemp -d)
    local TEMP_TMPDIR
    TEMP_TMPDIR=$(mktemp -d)

    # 2. Run the command with the temporary environment variables set.
    # The 'nix_auto_run=1' only applies if the command is not in the PATH.
    echo "Running command with temporary HOME=$TEMP_HOME and TMPDIR=$TEMP_TMPDIR..."
    
    # We execute the command with arguments, respecting the temporary environment
    HOME="$TEMP_HOME" TMPDIR="$TEMP_TMPDIR" NIX_AUTO_RUN=1 "$@"

    # 3. Clean up the temporary directories when the command exits
    echo "Cleaning up temporary directories..."
    rm -rf "$TEMP_HOME"
    rm -rf "$TEMP_TMPDIR"
}
