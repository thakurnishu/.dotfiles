# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
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

# Function
set-aws-profile() {
  local profiles selection

  mapfile -t profiles < <(aws configure list-profiles)

  if [[ ${#profiles[@]} -eq 0 ]]; then
    echo "No AWS profiles found."
    return 1
  fi

  echo "Available AWS profiles:"
  for i in "${!profiles[@]}"; do
    printf "%d) %s\n" "$((i + 1))" "${profiles[$i]}"
  done

  echo
  read -rp "Select a profile (1-${#profiles[@]}): " selection

  if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#profiles[@]} )); then
    echo "Invalid selection."
    return 1
  fi

  export AWS_PROFILE="${profiles[$((selection - 1))]}"
  echo "AWS profile set to: $AWS_PROFILE"
}


# Function to get the current git branch dynamically and indicate changes including new files
parse_git_branch() {
    # Check if inside a Git repository
    local branch=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null)
        if [[ -n "$branch" ]]; then
            # Check for changes: modified, staged, or untracked (new) files
            if ! git diff --quiet 2>/dev/null || \
               ! git diff --cached --quiet 2>/dev/null || \
               [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
                echo " \[\e[1;34m\]git(\[\e[1;31m\]$branch\[\e[1;34m\]) \[\e[1;33m\]✗"
            else
                echo " \[\e[1;34m\]git(\[\e[1;31m\]$branch\[\e[1;34m\])"
            fi
        fi
    fi
}

# Function to show active Python virtual environment (with emoji)
parse_python_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local env_name
        env_name=$(basename "$VIRTUAL_ENV")
        echo " \[\e[1;35m\]🐍 py(\[\e[1;36m\]$env_name\[\e[1;35m\])"
    fi
}

# Set the prompt to include the dynamic git branch status
#PROMPT_COMMAND='PS1="\[\e[1;32m\]➜  \[\e[38;5;80m\]\W$(parse_git_branch)\[\e[0m\] "'
PROMPT_COMMAND='PS1="\[\e[1;32m\]➜  \[\e[38;5;80m\]\W$(parse_python_env)$(parse_git_branch)\[\e[0m\] "'



SB_DIR=$HOME/Desktop/src/github.com/personal/second_brain
DOTFILE_DIR=$HOME/.dotfiles
HOMELAB_DIR=$HOME/Desktop/src/github.com/personal/homelab
BLOG_DIR=$HOME/Desktop/src/github.com/personal/blog/content

# Set to superior editing mode
set -o vi

# KeyBind
bind -x '"\C-l":clear'
bind -x '"\C-f":source ~/.local/bin/dir-selector.sh'

# Default Editor
export EDITOR=nvim
export VISUAL=nvim
#export MANPAGER='nvim +Man!'

## ZK
export SB_PATH="$HOME/Desktop/src/github.com/personal/second_brain"
export BLOG_PATH="$HOME/Desktop/src/github.com/personal/nishantlabs.cloud/app/content/posts"


# NeoVim stuff
PATH=$PATH:/usr/local/nvim/bin

# GO stuff
GOPATH=$HOME/go
PATH=$PATH:/usr/local/go/bin
PATH=$PATH:$GOPATH/bin
PATH="$HOME/.local/bin:$PATH"

# PHP stuff
# # Composer
export PATH="$HOME/.config/composer/vendor/bin:$HOME/.composer/vendor/bin:$PATH"


#~~~~~~~~ Alias ~~~~~~~~~~~~~~~

# color shell
alias ls='ls --color=auto'

# Change Dir
alias sb='cd ${SB_DIR} && nvim .'
alias dof='cd ${DOTFILE_DIR} && nvim .'
alias homelab='cd ${HOMELAB_DIR} && nvim .'
alias blog='cd ${BLOG_DIR} && nvim .'

alias v="nvim"

# ls
#alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Kubectl
alias k="kubectl"
source <(kubectl completion bash)
complete -F __start_kubectl k

# terragrunt
export PATH="/home/mahakal/.terragrunt/bin:$PATH"
alias tg='terragrunt'

# mise
eval "$($HOME/.local/bin/mise activate bash)"

# Autocompletes
source <(flux completion bash)
source <(zk completion bash)
source <(talosctl completion bash)
complete -C '$(which aws_completer)' aws

alias tf="terraform"

# dnf
alias dnf='sudo dnf install -y'
alias dnfu='sudo dnf update -y'
# apt 
alias apt='sudo apt install -y'
alias aptu='sudo apt update -y'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Rust
. "$HOME/.cargo/env"

# Load Angular CLI autocompletion.
source <(ng completion script)
