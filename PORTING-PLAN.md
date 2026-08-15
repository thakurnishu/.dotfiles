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

### [ ] 2. macOS system defaults
`modules/darwin/system.nix`. Candidates include Dock autohide, Finder
extensions, key repeat rate, and `_HIHideMenuBar`.

**Questions:** which settings do you actually want declared? Anything you'd
rather keep changing by hand? (Declared settings revert manual GUI changes on
each rebuild — that's the tradeoff of this choice.)

### [ ] 3. GUI apps (homebrew casks)
`modules/darwin/homebrew.nix`. Already installed here: `aerospace`, `ghostty`,
`displayplacer`, Brave. Decide the full cask list and whether nix-darwin should
adopt/manage the existing Homebrew installation.

**Questions:** which GUI apps beyond what's installed? Should nix uninstall
casks not listed (`onActivation.cleanup`)? Karabiner — still wanted, given it
failed to install earlier?

### [ ] 4. CLI packages
`modules/darwin/packages.nix`, derived from the ansible playbooks:

- **ai**: claude-code, codex, opencode
- **devops**: docker, helm, terragrunt, awscli, azure-cli, gcloud, mise, terraform
- **k8s**: kind, kubectl, kubebuilder, flux, talosctl
- **languages**: go, uv, bun, rust, php + composer + laravel
- **system**: fzf, ripgrep, tree, unzip, cmake, pkg-config, gpg, curl, lazygit, python3

Dropped as X11/Linux-only: `snapd`, `light`, `pavucontrol`, `maim`, `xclip`,
`picom`, `blueman`, and the `lib*-dev` Alacritty build deps.

**Questions:** is this list still current — anything to add/drop? Docker on
macOS means Docker Desktop (cask) or colima? Keep `mise` given Nix overlaps it?

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
