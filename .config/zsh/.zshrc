# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/moonburst/.config/zsh/completions:"* ]]; then export FPATH="/home/moonburst/.config/zsh/completions:$FPATH"; fi
#!/bin/zsh

# --- 0. Load Colors Early ---
autoload -Uz colors && colors
# --- 1. Zsh Core Settings (setopt, history behavior, zle) ---
# History settings (HISTFILE is set in ~/.zshenv)
setopt appendhistory
HISTSIZE=10000
SAVEHIST=10000
# Useful options (man zshoptions)
setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments
unsetopt BEEP # Beeping is annoying
# Zle (Zsh Line Editor) customizations
zle_highlight=('paste:none')
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line # Bind Ctrl-e to edit-command-line in editor
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# --- 2. Helper Functions (for sourcing files and managing plugins) ---
# Helper function to source files from $ZDOTDIR
zsh_add_file() {
    local file_path="$ZDOTDIR/$1"
    if [[ -f "$file_path" ]]; then
        source "$file_path"
    # else
        # Optional: uncomment for debugging missing files
        # echo "Warning: Zsh config file '$file_path' not found. Ensure it exists in $ZDOTDIR." >&2
    fi
}
# Simple plugin loading mechanism (adjust if you use a full plugin manager like Zinit, Oh My Zsh)
zsh_add_plugin() {
    local plugin_name="$1"
    local plugin_dir="$ZDOTDIR/plugins/$plugin_name" # Expected plugin install location
    if [[ -d "$plugin_dir" ]]; then
        # Common patterns for plugin loading (try sourcing these)
        if [[ -f "$plugin_dir/$plugin_name.plugin.zsh" ]]; then source "$plugin_dir/$plugin_name.plugin.zsh"; return; fi
        if [[ -f "$plugin_dir/$plugin_name.zsh" ]]; then source "$plugin_dir/$plugin_name.zsh"; return; fi
        if [[ -f "$plugin_dir/init.zsh" ]]; then source "$plugin_dir/init.zsh"; return; fi
        # Fallback: source all .zsh files directly in the plugin directory
        for f in "$plugin_dir"/*.zsh; do
            [[ -f "$f" ]] && source "$f"
        done
    # else
        # echo "Warning: Zsh plugin '$plugin_name' not found at '$plugin_dir'." >&2
    fi
}
# For specific completion files not managed by compinit's default fpath
zsh_add_completion() {
    local comp_file_path="$ZDOTDIR/completion/$1"
    if [[ -f "$comp_file_path" ]]; then
        # Add the directory containing the completion to fpath
        # Assumes $1 is something like "_fnm" and the file is $ZDOTDIR/completion/_fnm
        fpath+=("$(dirname "$comp_file_path")")
    # else
        # echo "Warning: Zsh completion file '$comp_file_path' not found." >&2
    fi
}

# --- 3. Load User Configurations from $ZDOTDIR ---
# 3.1. Load functions (e.g., ~/.config/zsh/functions)
zsh_add_file "functions"
# 3.2. Load environment variables for interactive shell (e.g., ~/.config/zsh/exports)
# This is where your EDITOR, TERMINAL, QT_QPA_PLATFORMTHEME would go.
zsh_add_file "exports"
# 3.3. Load aliases (e.g., ~/.config/zsh/aliases)
zsh_add_file "aliases"

# --- 4. Plugin Initialization ---
# Ensure these plugins are installed in ~/.config/zsh/plugins/
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "hlissner/zsh-autopair"

# --- 5. Zsh Completions (after all zstyles and fpath modifications) ---
# Ensure completion settings are done *before* compinit
autoload -Uz compinit
zmodload zsh/complist
zstyle ':completion:*' menu select
# zstyle ':completion::complete:lsof:*' menu yes select # Uncomment if needed
_comp_options+=(globdots) # Include hidden files.

# Call compinit *after* all completion related setups (zstyle, _comp_options, fpath)
compinit

if [[ -f "/usr/share/fzf/completion.zsh" ]]; then
    source "/usr/share/fzf/completion.zsh"
elif [[ -f "/usr/share/doc/fzf/examples/completion.zsh" ]]; then
    source "/usr/share/doc/fzf/examples/completion.zsh"
fi
if [[ -f "/usr/share/fzf/key-bindings.zsh" ]]; then
    source "/usr/share/fzf/key-bindings.zsh"
elif [[ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ]]; then
    source "/usr/share/doc/fzf/examples/key-bindings.zsh"
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Custom FZF default command example (uncomment if you use ripgrep)
export FZF_DEFAULT_COMMAND='rg --hidden -l ""'

# `cd` function override
cd() {
    builtin cd "$@" && ls
}

# --- 9. Prompt Setting (should be near the very end) ---
$XDG_CONFIG_HOME/fastfetch/fastfetch.sh
PROMPT="%{$fg[yellow]%}[%D{%T}] %{$fg[blue]%}moonburst@archlinux: %{$fg[green]%}%~%{$reset_color%} $"
