# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi


# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc


## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Function to get the current git branch dynamically
parse_git_branch() {
    # Check if inside a Git repository
    local branch=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null)
        if [[ -n "$branch" ]]; then
            # Check for changes in the repository
            if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
                echo " \[\e[1;34m\]git(\[\e[1;31m\]$branch\[\e[1;34m\]) \[\e[1;33m\]✗"
            else
                echo " \[\e[1;34m\]git(\[\e[1;31m\]$branch\[\e[1;34m\])"
            fi
        fi
    fi
}
PROMPT_COMMAND='PS1="\[\e[1;32m\]➜  \[\e[38;5;80m\]\W$(parse_git_branch)\[\e[0m\] "'

NOTES_DIR='/home/mahakal/Desktop/src/obsidian/mahakal_vault/MainNotes'
DOTFILE_DIR='/home/mahakal/.dotfiles'

# Set to superior editing mode
set -o vi

# KeyBind
bind -x '"\C-l":clear'
bind -x '"\C-f":source ~/.local/bin/dir-selector.sh'

# Default Editor
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim +Man!'

# NeoVim stuff
PATH=$PATH:/usr/local/nvim/bin

# GO stuff
GOPATH=$HOME/go
PATH=$PATH:/usr/local/go/bin
PATH=$PATH:$GOPATH/bin
PATH="$HOME/.local/bin:$PATH"

#~~~~~~~~ Alias ~~~~~~~~~~~~~~~

# Change Dir
alias sb='cd ${NOTES_DIR} && nvim .'
alias dof='cd ${DOTFILE_DIR} && nvim .'

alias v="nvim"

# ls
#alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Kubectl
alias k="kubectl"
source <(kubectl completion bash)
complete -F __start_kubectl k

alias tf="terraform"

# dnf
alias dnf='sudo dnf install -y'
alias dnfu='sudo dnf update -y'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
