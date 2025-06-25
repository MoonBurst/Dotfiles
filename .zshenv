# Define XDG Base Directory variables
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# Set ZDOTDIR for zsh configuration files
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# Application-specific XDG paths
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export GOPATH="${XDG_DATA_HOME}/go"
export GRADLE_USER_HOME="${XDG_DATA_HOME}/gradle"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export NPM_CONFIG_INIT_MODULE="${XDG_CONFIG_HOME}/npm/config/npm-init.js"
export NUGET_PACKAGES="${XDG_CACHE_HOME}/NuGetPackages"
export PASSWORD_STORE_DIR="${XDG_DATA_HOME}/pass"
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"



# Add fnm to PATH
export PATH="/home/moonburst/.local/share/fnm:$PATH"
