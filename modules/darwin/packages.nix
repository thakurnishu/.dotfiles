# CLI packages — Phase 4. Ported from ansible-setup-script/playbooks/.
#
# Every attribute name here was verified to resolve in nixpkgs before being
# added. Versions come from flake.lock, so these only move when you run
# `nix flake update`.
#
# GUI apps live in homebrew.nix, not here.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [

    # --- language toolchains ---------------------------------------------
    # Nix owns these outright; mise was dropped to avoid two systems
    # managing the same runtimes.
    go
    bun
    uv
    nodejs
    rustup

    # go install ... from language.yaml, packaged in nixpkgs instead
    grpcurl
    hugo

    # --- containers -------------------------------------------------------
    # macOS has no native Docker daemon. colima provides the Linux VM;
    # start it with `colima start` before using docker or kind.
    colima
    docker
    docker-compose

    # --- kubernetes -------------------------------------------------------
    kubectl
    kind
    kubebuilder
    fluxcd
    talosctl
    kubernetes-helm

    # --- cloud / IaC ------------------------------------------------------
    terraform
    terragrunt
    awscli2
    azure-cli
    google-cloud-sdk

    # --- AI CLIs ----------------------------------------------------------
    # ai.yaml installed these via curl|bash, npm and `uv tool`; all four
    # are packaged, so they become declarative and pinned.
    claude-code
    opencode
    codex
    graphify

    # git credential helper (see dotfiles/.gitconfig) + gh CLI
    gh

    # --- editor / dev support --------------------------------------------
    neovim
    tmux
    tree-sitter
    prettierd
    zk
    lazygit

    # tmux status-right runs #(pomo)
    pomo

    # --- shell ------------------------------------------------------------
    # Replaces the bash PROMPT_COMMAND/PS1 and oh-my-zsh.
    starship

    # --- system CLI -------------------------------------------------------
    fzf
    ripgrep
    tree
    unzip
    cmake
    pkg-config
    python3
    gnupg
    curl
    bash-completion
  ];

  # Deliberately excluded:
  #   mise          — Nix owns the language toolchains now
  #   php/composer  — no Laravel work on this Mac
  #   displayplacer — not in nixpkgs; stays a Homebrew formula
  #
  # Dropped as X11/Linux-only: snapd, light, pavucontrol, maim, xclip,
  # picom, blueman, uxplay, and the lib*-dev Alacritty build deps.
}
