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
PS1='[\W]\$ '
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

# NeoVim stuff
PATH=$PATH:/usr/local/nvim/bin

# GO stuff
GOPATH=$HOME/go
PATH=$PATH:/usr/local/go/bin
PATH=$PATH:$GOPATH/bin
PATH="$HOME/.local/bin:$PATH"

#~~~~~~~~ Alias ~~~~~~~~~~~~~~~

# Change Dir
alias sb='cd ${NOTES_DIR}'
alias df='cd ${DOTFILE_DIR}'

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
