#!/bin/sh
export ZDOTDIR=$HOME/.config/zsh
HISTFILE=~/.zsh_history
setopt appendhistory
HISTSIZE=10000
SAVEHIST=10000


# some useful options (man zshoptions)
setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments
stty stop undef        # Disable ctrl-s to freeze terminal.
zle_highlight=('paste:none')

# beeping is annoying
unsetopt BEEP

# completions
autoload -Uz compinit
zstyle ':completion:*' menu select
# zstyle ':completion::complete:lsof:*' menu yes select
zmodload zsh/complist
# compinit
_comp_options+=(globdots)        # Include hidden files.

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search


# Colors
autoload -Uz colors && colors

# Useful Functions
source "$ZDOTDIR/functions"
source ~/.bash_aliases

# Normal files to source
zsh_add_file "exports"
zsh_add_file "aliases"

# Plugins
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "hlissner/zsh-autopair"

# zsh_add_completion "esc/conda-zsh-completion" false
# For more plugins: https://github.com/unixorn/awesome-zsh-plugins
# More completions https://github.com/zsh-users/zsh-completions

# FZF 
# TODO update for mac
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f $ZDOTDIR/completion/_fnm ] && fpath+="$ZDOTDIR/completion/"
# export FZF_DEFAULT_COMMAND='rg --hidden -l ""'
compinit

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line

# Environment variables set everywhere
export EDITOR="nano"
export TERMINAL="kitty"

# For QT Themes
export QT_QPA_PLATFORMTHEME=qt5ct

export PATH="/home/moonburst/.local/share/fnm:$PATH"
#steam fix?
export DXVK_FRAME_RATE=0

# Needs to be at or near the end of file
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

cd() {
  builtin cd "$@" && ls
}

###################################
#   NEED TO BE NEAR END OF FILE   #
###################################

# Initialize fnm
#eval "$(fnm env --use-on-cd)"

# initialize zoxide
#eval "$(zoxide init zsh)"



# Needs to be at the end of file
#eval "$(starship init zsh)"
fastfetch --logo /home/moonburst/.config/fastfetch/test.png --logo-width 55 --logo-height 20

PROMPT="%{$fg[yellow]%}[%D{%T}] %{$fg[blue]%}moonburst@archlinux: %{$fg[green]%}%~%{$reset_color%} $"
