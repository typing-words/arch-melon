#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"
fastfetch

# ---- Terminal rice (each tool is only used if installed) ----
# Prompt
if command -v starship >/dev/null; then
    # Blank line between the command you type and its output (set before starship,
    # which appends its timer to PS0)
    PS0='\n'
    eval "$(starship init bash)"
fi
# Smarter cd: "z proj" jumps to the most used folder matching "proj"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
# Fuzzy history search with Ctrl+R, file search with Ctrl+T
command -v fzf >/dev/null && eval "$(fzf --bash)"
# ls with icons and git status
if command -v eza >/dev/null; then
    # Folders in classic manila folder yellow, bold
    export EZA_COLORS="di=1;38;2;248;215;117"
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias tree='eza --tree --icons'
fi
# cat with syntax highlighting
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'

# Default terminal editor (git commit, sudoedit, crontab -e...)
export EDITOR=nvim
export VISUAL=nvim
