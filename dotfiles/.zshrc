# .zshrc — macOS. Ported from the Ubuntu .bashrc (the real config; the old
# .zshrc was a near-empty oh-my-zsh stub).
#
# Dropped, because Nix now provides these on PATH:
#   nvm, cargo env, gcloud path.bash.inc, opencode/bun PATH lines,
#   /usr/local/go/bin, /usr/local/nvim/bin, mise, composer (no PHP here)
# Dropped as Linux-only: dnf/apt aliases, `ls --color=auto` (GNU-only)
#
# Auto-tmux is NOT here: Ghostty launches tmux directly (see
# .config/ghostty/config). Duplicating it would risk nested sessions.

# ---------------------------------------------------------------- PATH -----
export GOPATH="$HOME/go"
path=(
  "$HOME/.local/bin"                 # screenshot, display-sync, tmux-sessionizer
  "$GOPATH/bin"                      # go install targets
  "${KREW_ROOT:-$HOME/.krew}/bin"    # kubectl plugins
  $path
)
typeset -U path                      # de-duplicate
export PATH

# -------------------------------------------------------------- editor -----
export EDITOR=nvim
export VISUAL=nvim

# ----------------------------------------------------------- vi keybinds ---
# bash: set -o vi
bindkey -v
KEYTIMEOUT=1                         # kill the escape-key lag

# bash: bind -x '"\C-l":clear'
bindkey '^L' clear-screen

# bash: bind -x '"\C-f":source ~/.local/bin/dir-selector.sh'
_dir_selector() {
  [[ -r "$HOME/.local/bin/dir-selector.sh" ]] && source "$HOME/.local/bin/dir-selector.sh"
  zle reset-prompt
}
zle -N _dir_selector
bindkey '^F' _dir_selector

# ---------------------------------------------------------- completions ----
autoload -Uz compinit && compinit -u
autoload -Uz bashcompinit && bashcompinit   # for `complete -C` style below

# zsh-native completions, guarded so a missing tool doesn't break startup
(( $+commands[kubectl] ))  && source <(kubectl completion zsh)
(( $+commands[flux] ))     && source <(flux completion zsh)
(( $+commands[zk] ))       && source <(zk completion zsh)
(( $+commands[talosctl] )) && source <(talosctl completion zsh)
(( $+commands[helm] ))     && source <(helm completion zsh)
(( $+commands[aws_completer] )) && complete -C "$(command -v aws_completer)" aws

# make `k` complete like kubectl
(( $+commands[kubectl] )) && compdef __start_kubectl k

# ------------------------------------------------------------- history -----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
setopt AUTO_CD INTERACTIVE_COMMENTS

# ------------------------------------------------------------- aliases -----
alias k="kubectl"
alias tf="terraform"
alias tg="terragrunt"
alias v="nvim"
alias vim="nvim"

# BSD ls: --color=auto is GNU-only and errors here
alias ls='ls -G'
alias grep='grep --color=auto'

# macOS package management, replacing the dnf/apt aliases
alias brewi='brew install'
alias brewu='brew update && brew upgrade'

# -------------------------------------------------------- aws functions ----
# Ported from .bashrc. Note zsh arrays are 1-indexed (bash is 0-indexed),
# and mapfile/`read -rp` don't exist in zsh — rewritten accordingly.

set-aws-profile() {
  local -a profiles
  local selection

  profiles=("${(@f)$(aws configure list-profiles 2>/dev/null)}")

  if (( ${#profiles[@]} == 0 )) || [[ -z "${profiles[1]}" ]]; then
    echo "No AWS profiles found."
    return 1
  fi

  echo "Available AWS profiles:"
  local i
  for (( i = 1; i <= ${#profiles[@]}; i++ )); do
    printf "%d) %s\n" "$i" "${profiles[$i]}"
  done

  echo
  read "selection?Select a profile (1-${#profiles[@]}): "

  if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#profiles[@]} )); then
    echo "Invalid selection."
    return 1
  fi

  export AWS_PROFILE="${profiles[$selection]}"
  echo "AWS profile set to: $AWS_PROFILE"
}

login-aws-profile() {
  set-aws-profile && aws login --profile "$AWS_PROFILE"
}

docker-login-aws() {
  local region account_id

  if [[ -z "$AWS_PROFILE" ]]; then
    echo "AWS_PROFILE is not set. Running login-aws-profile..."
    login-aws-profile || return 1
  fi

  read "region?Enter AWS region (e.g., us-east-1): "
  if [[ -z "$region" ]]; then
    echo "Region cannot be empty."
    return 1
  fi

  account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
  if [[ -z "$account_id" ]]; then
    echo "Failed to get AWS account ID. Check your AWS credentials."
    return 1
  fi

  echo "Using AWS_PROFILE: $AWS_PROFILE"
  echo "Logging into ECR for account: $account_id in region: $region"

  if aws ecr get-login-password --region "$region" \
      | docker login --username AWS \
        --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com"; then
    echo "ECR login successful."
  else
    echo "ECR login failed."
    return 1
  fi
}

# --------------------------------------------------- project shortcuts -----
# From .bashrc, with ~/Desktop/src/... remapped to ~/src/... (Phase 7).
SB_DIR="$HOME/src/github.com/personal/second_brain"
DOTFILE_DIR="$HOME/.dotfiles"
HOMELAB_DIR="$HOME/src/github.com/personal/homelab"
BLOG_DIR="$HOME/src/github.com/personal/blog/content"

alias sb='cd ${SB_DIR} && nvim .'
alias dof='cd ${DOTFILE_DIR} && nvim .'
alias homelab='cd ${HOMELAB_DIR} && nvim .'
alias blog='cd ${BLOG_DIR} && nvim .'

# zk. SB_PATH matches the obsidian.nvim workspace in nvim/after/plugin/.
export SB_PATH="$HOME/src/github.com/personal/second_brain"
export BLOG_PATH="$HOME/src/github.com/personal/nishantlabs.cloud/app/content/posts"

# -------------------------------------------------------------- prompt -----
# Replaces the bash PROMPT_COMMAND/PS1 pair (parse_git_branch +
# parse_python_env). starship covers both, plus k8s context and AWS profile.
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Directory shortcuts (sb / dof / homelab / blog) and the zk SB_PATH /
# BLOG_PATH exports are deliberately omitted until the code layout on this
# Mac is decided.
