# CLI packages — Phase 4. Ported from ansible-setup-script/playbooks/.
#
# Every attribute name here was verified to resolve in nixpkgs before being
# added. Versions come from flake.lock, so these only move when you run
# `nix flake update`.
#
# GUI apps live in homebrew.nix, not here.
{ pkgs, ... }:
let
  # Your own zk, not the unrelated nixpkgs package of the same name.
  zk-personal = pkgs.callPackage ../pkgs/zk.nix { };
in
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

    # helm wrapped with its plugins. `helm plugin install` would write to
    # ~/Library/helm/plugins -- untracked machine-local state that would not
    # survive a fresh install. The wrapper sets HELM_PLUGINS to a store path,
    # so it OWNS plugin resolution: hand-installed plugins stop being visible,
    # and versions move with flake.lock rather than `helm plugin update`.
    # More available under pkgs.kubernetes-helmPlugins: helm-secrets, helm-s3,
    # helm-git, helm-unittest, helm-mapkubeapis, helm-cm-push, helm-schema.
    (wrapHelm kubernetes-helm {
      plugins = with kubernetes-helmPlugins; [ helm-diff ];
    })

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

    # Agent multiplexer: a background server that hosts the CLIs above, and
    # reports each one as working / blocked / idle in a sidebar.
    #
    # Persistence has two tiers, and they are NOT the same: detaching
    # (prefix+q) or closing the lid keeps the processes alive, but a server
    # restart or reboot only snapshot-restores the shape -- workspaces, tabs,
    # panes, cwd, layout -- and the processes are gone. Claude Code resumes
    # its conversation via herdr's integration; a plain shell does not.
    #
    # Overlaps tmux; dotfiles/herdr/config.toml moves the prefix off ctrl+b so
    # the two can nest. Packaged in nixpkgs, so the upstream `curl | sh`
    # installer is not used.
    herdr

    # git credential helper (see dotfiles/.gitconfig) + gh CLI
    gh

    # --- editor / dev support --------------------------------------------
    neovim
    tmux
    tree-sitter
    prettierd
    zk-personal
    lazygit

    # tmux status-right runs #(pomo)
    pomo

    # --- shell ------------------------------------------------------------
    # Replaces the bash PROMPT_COMMAND/PS1 and oh-my-zsh.
    starship

    # --- system CLI -------------------------------------------------------
    fzf
    # Charm's shell-script TUI toolkit. Used by .local/bin/session-picker for
    # the new-window menu; that script degrades to a plain `read` menu if this
    # ever goes missing, so it is a nicety rather than a hard dependency.
    gum
    ripgrep
    jq # statusline.sh parses Claude Code's JSON input
    htop

    # NOTE: coreutils deliberately NOT installed. Nix's coreutils provides
    # `date`, not `gdate` (the g-prefix is a Homebrew convention), so it
    # wouldn't fix statusline.sh anyway — and putting GNU coreutils on PATH
    # shadows BSD `ls`, where -G means "colorize"; GNU -G means
    # "--no-group". That would silently break `alias ls='ls -G'`.
    # statusline.sh uses BSD `date -j -u -f` instead, with a gdate branch
    # in case Homebrew coreutils is ever installed.
    tree
    unzip
    cmake
    gnumake # telescope-fzf-native has build = 'make'
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
