# Porting `ubuntu-config` → `macos-config`

Target: MacBook (Apple Silicon), macOS 26 / Darwin 25.3, user `nishantsingh`.
Source branch: `ubuntu-config` (50 files). Nothing is ported until its phase is
agreed — each phase opens with questions before any file is written.

## Decisions already locked

| Decision | Choice |
|---|---|
| Shell | Port `.zshrc` only; delete `.bashrc` |
| Terminal | Ghostty replaces Alacritty — full port incl. auto-tmux |
| Window manager | AeroSpace replaces i3 (already built + verified) |
| Linux-only files | Deleted on this branch (history retains them) |
| Package/config manager | **Nix**: nix-darwin + home-manager, flakes |
| Nix depth | `home.file` — configs stay verbatim, editable plain text |
| System scope | nix-darwin **also** manages macOS defaults |
| Installer | Determinate Systems |
| Repo layout | Modular: `hosts/` + `modules/` |

Consequences: home-manager replaces `scripts/linkAllFile.sh`, and the
nix-darwin homebrew module replaces any Brewfile. GUI apps stay Homebrew
casks — `.app` bundles don't work well from the Nix store, and Nix-installed
GUI apps can't be configured through their own UI.

## Target layout

```
flake.nix
hosts/macbook/default.nix
modules/
  darwin/homebrew.nix      # casks: ghostty, aerospace, brave…
  darwin/system.nix        # macOS defaults
  darwin/packages.nix      # CLI tools
  home/default.nix         # home.file wiring
dotfiles/                  # verbatim config files
  .zshrc  .tmux.conf  .gitconfig  .aerospace.toml
  ghostty/config
  ssh/config
  .local/bin/{screenshot,display-sync,tmux-sessionizer,dir-selector.sh}
  nvim/  claude/  opencode/
PORTING-PLAN.md
```

---

## Phases

Ordered by dependency. `[ ]` = not started.

### [x] 0. Bootstrap Nix — DONE
Determinate Nix 3.21.9 (Nix 2.34.8), flakes enabled.

<details><summary>original step</summary>
Needs interactive sudo; can't be driven from the agent.
```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
</details>

### [x] 1. Flake skeleton — BUILT (activation pending)
Decisions: channel `nixpkgs-unstable`, config name `macbook`, home-manager as
a nix-darwin module, `nix.enable = false` for Determinate.

`nix build .#darwinConfigurations.macbook.system` → exit 0.
`nix flake check` → both configurations pass.

Remaining: first activation needs sudo, run by you:
```
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.dotfiles#macbook
```

### [x] 2. macOS system defaults — BUILT (activation pending)
`modules/darwin/system.nix`, 13 settings, all verified present in the
evaluated config:

- **tiling**: `spaces.spans-displays=true` (was a manual step), `dock.mru-spaces=false`
- **menu bar**: `_HIHideMenuBar=true` (auto-hide; reveals on hover, nothing removed)
- **keyboard**: `KeyRepeat=2`, `InitialKeyRepeat=15`, `ApplePressAndHoldEnabled=false`
- **dock**: `autohide=true`, `show-recents=false`
- **finder**: extensions, path bar, status bar, `FXDefaultSearchScope="SCcf"`, folders first

Left manual: `screencapture.location` (never decided; Cmd-Shift-3/4 still
writes to Desktop).

`spans-displays` needs a logout/login to take effect.

### [x] 3. GUI apps (homebrew casks) — BUILT (activation pending)
`modules/darwin/homebrew.nix`. All 8 cask names verified against `brew info`
before writing; all present in the evaluated config.

- brew-managed already: `aerospace`, `ghostty`, `claude-code`
- new: `font-jetbrains-mono-nerd-font` (required by Phase 6)
- adopted from manual installs: `brave-browser`, `whatsapp`,
  `microsoft-teams`, `stats` — via `HOMEBREW_CASK_OPTS = "--adopt"`

`cleanup = "none"`, `autoUpdate = false`, `upgrade = false`.

Karabiner dropped: it was only needed to remap Brave's Ctrl keys, which
became moot once workspaces moved to `cmd`.

Note: `displayplacer` is still a brew *formula*; it moves to Nix in Phase 4.

### [x] 4. CLI packages — BUILT (activation pending)
`modules/darwin/packages.nix`, 40 packages. Every nixpkgs attribute name was
verified to resolve *before* being written.

- **languages**: go, bun, uv, nodejs, rustup (+ grpcurl, hugo)
- **containers**: colima, docker, docker-compose (`colima start` first)
- **k8s**: kubectl, kind, kubebuilder, fluxcd, talosctl, kubernetes-helm
- **cloud/IaC**: terraform, terragrunt, awscli2, azure-cli, google-cloud-sdk
- **ai**: claude-code, opencode, codex, graphify — were curl|bash / npm / uv
- **editor**: neovim, tmux, tree-sitter, prettierd, zk, lazygit
- **system**: fzf, ripgrep, tree, unzip, cmake, pkg-config, python3, gnupg,
  curl, bash-completion

`nixpkgs.config.allowUnfree = true` in hosts/macbook — needed by terraform
(BUSL 1.1) and claude-code (proprietary).

Excluded: mise (Nix owns toolchains), php/composer/laravel, opentofu,
uxplay (macOS has AirPlay Receiver built in). `displayplacer` is not in
nixpkgs and stays a brew formula. `gh` deferred to Phase 8.

`claude-code` moved out of homebrew.nix into Nix; remove the stale cask once
with `brew uninstall --cask claude-code`.

Build → exit 0, 135 binaries in the system profile. First build pulled ~11GB
(google-cloud-sdk 571MB, azure-cli 297MB, qemu 244MB via colima, terraform
compiled from source); later rebuilds reuse the store and take seconds.

### [ ] 5. Shell — `.zshrc`
Port 135 lines. Known fixes: `EDITOR=/usr/bin/nvim` → nix path;
`/home/mahakal/.nix-profile/…` line → macOS equivalent. Delete `.bashrc`.

**Questions:** walk through the aliases together? Keep Oh-My-Zsh/plugins as-is
or let home-manager own them?

### [ ] 6. Terminal — Ghostty
New `dotfiles/ghostty/config` replacing `.alacritty.toml`: JetBrainsMono Nerd
Font 16, `window-decoration = false`, catppuccin, `command = tmux`.
Nerd Font must be added as a cask (none installed on this Mac).

**Questions:** which catppuccin flavour (mocha/macchiato/frappe/latte)?

### [ ] 7. Window manager — AeroSpace
Move the working `~/.aerospace.toml` + `~/.local/bin/display-sync` into the
repo under home-manager. Delete `.config/i3/`.

**Questions:** move-and-symlink, or copy and keep the live file standalone?
(Was asked earlier, still unanswered.)

### [ ] 8. Git + SSH
`.gitconfig`: strip the three `/home/mahakal/` paths, repoint the `includeIf`
work path, decide the credential helper (`gh` isn't installed).
`~/.ssh/config`: net-new — nothing exists in either branch.

**Questions:** separate work GitHub account? Where do work repos live on this
Mac? SSH keys, `gh` over HTTPS, or both? Generate new ed25519 keys?

### [ ] 9. tmux
`.tmux.conf` (45 lines) scanned clean of Linux-isms — likely verbatim.

**Questions:** any plugins (tpm) needing separate handling?

### [ ] 10. `.local/bin` scripts
`screenshot` (macOS version written + verified — clipboard-only),
`display-sync` (new), `tmux-sessionizer`, `dir-selector.sh`.

**Questions:** do `tmux-sessionizer` / `dir-selector.sh` hardcode Linux paths
or use `find` flags that differ on BSD? (Needs a read-through together.)

### [ ] 11. Editor — nvim
22 files, Lua. Expected portable; `lazy-lock.json` pins plugins.

**Questions:** carry `lazy-lock.json` over verbatim, or re-resolve on this Mac?

### [ ] 12. Claude + opencode configs
`.config/claude/{CLAUDE.md,settings.json,statusline.sh}`,
`.config/opencode/skills/**` (4 skills).

**Questions:** does `settings.json` or `statusline.sh` reference Linux paths?

### [ ] 13. Cleanup
Delete `.config/i3/`, `install.sh`, `ansible-setup-script/`, `.alacritty.toml`,
`.bashrc`, `scripts/linkAllFile.sh`. Rewrite `README.md` for macOS.

**Questions:** replace `install.sh` with a one-command bootstrap script?
