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

  # Not in nixpkgs; built from the upstream tag. See the file for the
  # licensing caveat (NPDL-1.0, meta.license deliberately unset).
  llm-checker = pkgs.callPackage ../pkgs/llm-checker.nix { };

  # nixpkgs has no standalone `telnet`; the binary lives in GNU inetutils.
  # Installing inetutils outright is not safe here -- it also ships hostname,
  # ping, ping6, ifconfig, logger, traceroute and whois, every one of which
  # would shadow the macOS system version on PATH. Same trap as the coreutils
  # NOTE below, with a worse blast radius: GNU `ifconfig` does not understand
  # macOS interfaces, and GNU `ping` wants a raw socket it is not setuid for.
  # So link out the one binary that was actually wanted.
  telnet = pkgs.runCommand "telnet-${pkgs.inetutils.version}" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.inetutils}/bin/telnet $out/bin/telnet
  '';
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
    #
    # The VM must be CREATED with Rosetta on, because the work cluster is amd64
    # while this Mac is arm64 (see the DOCKER_DEFAULT_PLATFORM note below):
    #
    #     colima start --vz-rosetta --memory 8
    #
    # 8 GB rather than colima's 4 GB default: the work images are amd64 and go
    # through Rosetta, and 4 was tight. The host has 24 GB, so this still
    # leaves plenty. Unlike arch, memory and cpu CAN be changed on an existing
    # VM -- `colima stop && colima start --memory 8` keeps every image and
    # volume. Only arch is the one-way door described below.
    #
    # Only the first `colima start` reads these flags; afterwards the VM is
    # described by ~/.colima/default/colima.yaml (`rosetta: true`), which is
    # colima-GENERATED and deliberately NOT tracked in this repo -- it is
    # interleaved with machine state (disk size, mounts) that means nothing on
    # another box. Nix does not touch it, so a rebuild never clobbers it; only
    # a fresh machine or `colima delete` needs the flag again.
    #
    # DO NOT "simplify" this to `arch: x86_64` in that file. Two independent
    # reasons, either one fatal:
    #   1. arch cannot be changed on an existing VM. It forces a delete and
    #      recreate, destroying every local image and volume.
    #   2. vmType: vz is Apple's Virtualization framework, which only runs
    #      host-architecture guests. An x86_64 guest silently falls back to
    #      full QEMU emulation -- far slower for EVERYTHING, not just amd64
    #      workloads, and virtiofs mounts are lost.
    # aarch64 + vz + rosetta:true is the fast path and the intended end state.
    #
    # Rosetta makes amd64 images RUNNABLE here; it does not make them the right
    # default. Nothing on this machine sets DOCKER_DEFAULT_PLATFORM, and it
    # should stay that way -- it was briefly exported machine-wide from a
    # .zshenv and caused three separate failures, each reproduced:
    #   1. `docker build` honours the variable but `docker compose build`
    #      IGNORES it, so the two silently disagreed about arch on one machine.
    #      A locally built amd64 base image then failed `FROM` resolution under
    #      compose with "no match for platform in manifest".
    #   2. Buildkit cache mounts are not keyed by platform, so arm64 object
    #      files were reused by an amd64 build: "Relocations in generic ELF
    #      (EM: 183)" -- EM 183 being AArch64.
    #   3. RabbitMQ 3.13 crashes under emulated amd64; the Erlang BEAM JIT
    #      miscompiles through Rosetta. Native arm64 it starts in ~3s.
    # So local work is native arm64. Anything built FOR THE CLUSTER must say so
    # at the point of build -- `docker build --platform linux/amd64` -- rather
    # than relying on ambient environment. Do not re-add the global export.
    colima
    docker
    docker-compose

    # --- kubernetes -------------------------------------------------------
    kubectl
    # Cluster TUI. Not optional the way the other kube tools are: the `tools`
    # space that .local/bin/herdr-tools-space builds on every session start
    # runs `k9s` in its one tab, so dropping this leaves that tab erroring.
    k9s
    kind
    kubebuilder
    fluxcd
    talosctl
    # Cluster backup/restore. CLI only -- the server-side component still has
    # to be installed into each cluster with `velero install`.
    velero

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
    # GitHub PR/issue TUI. Installed as a plain package rather than via
    # `gh extension install`, which writes to ~/.local/share/gh/extensions --
    # untracked state that would not survive a fresh install. The trade-off is
    # that the command is `gh-dash`, not `gh dash`: gh only discovers
    # extensions in its own data dir. Making `gh dash` work would mean
    # home-manager's programs.gh.extensions, which also takes ownership of
    # ~/.config/gh/config.yml -- hand-written here, and not in this repo.
    gh-dash

    # --- editor / dev support --------------------------------------------
    neovim
    tmux
    tree-sitter
    prettierd
    zk-personal

    # Hardware-aware "which local LLM can this Mac run?" CLI. Also ships an
    # MCP server (`llm-checker-mcp`) if it is ever worth wiring into Claude.
    llm-checker
    lazygit

    # Diff viewer built for reading changes you did NOT write: a file sidebar,
    # side-by-side panes, and `hunk diff --watch`, which reloads as the working
    # tree changes -- so an agent's edits can be reviewed as they land rather
    # than as one dump at the end. Not a replacement for lazygit's diff; the
    # watch mode is the part lazygit has no answer to.
    hunk

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
    # 7-Zip, official port (26.02). The binary is `7zz`, NOT `7z` -- that
    # name belongs to the `p7zip` attribute, a community fork stuck at 17.06
    # because upstream p7zip went unmaintained. This is the real thing,
    # released by Igor Pavlov, and it is what to use; p7zip was tried here
    # and removed in favour of it.
    # NOTE: no RAR support out of the box -- that codec is unfree and lives
    # in the separate `_7zz-rar` attribute.
    _7zz
    cmake
    gnumake # telescope-fzf-native has build = 'make'
    pkg-config
    python3
    gnupg
    curl
    bash-completion

    # Reaching a port by hand (`telnet host 5432`). See the let-binding above
    # for why this is not plain `inetutils`.
    telnet
  ];

  # Deliberately excluded:
  #   mise          — Nix owns the language toolchains now
  #   php/composer  — no Laravel work on this Mac
  #   displayplacer — not in nixpkgs; stays a Homebrew formula
  #
  # Dropped as X11/Linux-only: snapd, light, pavucontrol, maim, xclip,
  # picom, blueman, uxplay, and the lib*-dev Alacritty build deps.
}
