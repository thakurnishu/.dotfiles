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

### [x] 5. Shell — `.zshrc` BUILT (activation pending)
Ported from **`.bashrc`** (247 lines, the real config) into
`dotfiles/.zshrc`, not from the old near-empty `.zshrc` stub.

bash→zsh conversions made:
- `set -o vi` → `bindkey -v` (+ `KEYTIMEOUT=1`)
- `bind -x` Ctrl-L / Ctrl-F → `bindkey` + a `zle` widget
- `mapfile` → `${(@f)...}`; `read -rp` → `read "var?prompt"`
- **arrays re-indexed 1-based** (bash is 0-based) in `set-aws-profile`
- `completion bash` → `completion zsh`; `complete -C` needs `bashcompinit`
- custom `PS1`/`PROMPT_COMMAND` → **starship** (`dotfiles/starship.toml`)

Dropped (Nix provides them): nvm, cargo env, gcloud `path.bash.inc`,
opencode/bun/go PATH lines, mise, composer. Dropped as Linux-only:
`dnf`/`apt` aliases, `ls --color=auto` → `ls -G` (BSD).
Kept: krew PATH, GOPATH, `~/.local/bin`.

Auto-tmux deliberately omitted — Ghostty launches tmux (Phase 6);
duplicating it risks nested sessions.

Deferred: `sb`/`dof`/`homelab`/`blog` aliases and zk `SB_PATH`/`BLOG_PATH`,
pending a decision on the code layout for this Mac.

Verified: `zsh -n` clean; all 4 functions define; `set-aws-profile` picks
the right profile (selecting 3 of 3 → `prod`, proving the index conversion);
all 3 error paths return 1.

### [x] 6. Terminal — Ghostty BUILT (activation pending)
`dotfiles/ghostty/config` replaces `.alacritty.toml`.

```
font-family = JetBrainsMono Nerd Font Mono
font-size = 16
theme = Catppuccin Mocha
window-decoration = false
command = tmux new-session -A -s main
```

Two findings from validating against Ghostty itself:
- the theme id is the **display name with spaces**; `catppuccin-mocha`
  fails with "theme not found"
- `+show-config` does NOT validate — `+validate-config` does. Both controls
  (bad theme, bogus key) error correctly; the real config exits 0.

Font: macOS reports 6 JetBrains families; `Nerd Font Mono` chosen as the
strictly-monospace one (the only variant Ghostty itself lists).

tmux: Alacritty ran plain `tmux` (new numbered session per window). Changed
to `-A -s main` because `~/.local/bin/tmux-sessionizer` uses
`tmux switch-client`, which only works from inside tmux, and numbered
sessions would pollute its project-session list. Each Ghostty window is a
separate client, so switching one doesn't drag the others.

Padding/extras deliberately omitted, matching Alacritty's defaults.

### [x] 7. Window manager — AeroSpace BUILT (activation pending)
`~/.aerospace.toml` moved into `dotfiles/.aerospace.toml`, deployed by
home-manager. **The live file is now a read-only store symlink** — edit
`~/.dotfiles/dotfiles/.aerospace.toml` and rebuild; `alt-shift-c` reloads
whatever was last deployed.

`displayplacer` is now declared in `homebrew.brews`. It was only mentioned in
a *comment* before — installed by hand, so a fresh Mac would have had
`alt-shift-s` fail silently. Not in nixpkgs, so Homebrew is the only option.

Checked: AeroSpace's exec environment has **no PATH** (only HOME, TMPDIR,
SSH_AUTH_SOCK, XPC_SERVICE_NAME, OSLogRateLimit). All bindings survive it
because they use absolute paths or /usr/bin tools, and display-sync exports
`/opt/homebrew/bin` itself.

### [x] 8. Git + SSH — BUILT (activation pending)

**`~/.ssh/config` is deliberately NOT tracked or Nix-managed.** It stays a
plain local file, exactly as it was: 9 hosts, single file, no `config.local`
split. Reason: this repo is public and the config lists LAN addresses
(192.168.1.203-206), an EC2 host, an employer GitLab and multiple accounts.

Consequence: SSH is not reproducible on a new Mac — you'd recreate
`~/.ssh/config` by hand. Accepted tradeoff.

Note 5 of 6 keys it references are MISSING here; only `github_personal`
exists. Those hosts error only when used.

**Tracked:** `dotfiles/.gitconfig` only.
- `includeIf` repointed to `~/src/github.com/work/` (Phase 7 layout);
  trailing slash required or the rule never matches
- gh credential helpers kept, with an **absolute** Nix path — git can invoke
  helpers with a minimal PATH, same failure mode as Ghostty/tmux
- `gh` added to packages

Verified: gitconfig parses (12 entries incl. includeIf); after restoring the
original ssh config, `ssh -T git@github.com` authenticates as thakurnishu.

**Pre-existing leak (not from this phase):** `.config/claude/CLAUDE.md` is
already tracked and public on both branches, listing the employer name and
internal repo names (fcc-monorepo-tms-*, app-fcc-*). Address in Phase 12.

### [x] 9. tmux — BUILT (done early, alongside Phase 6)
`dotfiles/.tmux.conf`. Ported near-verbatim; no tpm/plugins to handle.

Checked and fine on macOS: `tmux-256color` terminfo exists (a classic macOS
breakage), `status-bg default`, mouse, vi mode-keys, base-index.

Changes:
- **added** pbcopy clipboard bindings (`y`, `Enter`, mouse-drag-end in
  copy-mode-vi). The Linux config had none, so yanking only reached tmux's
  internal buffer.
- **added** `pomo` to packages — `status-right` runs `#(pomo)` and it wasn't
  installed here (nixpkgs has pomo 1.2.1).
- kept the gruvbox status greys rather than matching Catppuccin.

Verified by starting a throwaway server (`tmux -L tmuxcheck -f <config>`):
parsed OK, history-limit/mouse/status-position/base-index/default-terminal/
mode-keys all applied, both copy-pipe bindings registered.

### [x] 10. `.local/bin` scripts — BUILT (done with Phase 7)
All four now in `dotfiles/.local/bin/`, deployed with `executable = true`
(store files are 0444 by default; verified the built paths are `-r-xr-xr-x`).

Code layout decided: **`~/src/github.com/{personal,work}`, `~/src/gitlab.com`**
— replaces the Linux `~/Desktop/src/...`. This also unblocks the Phase 5
aliases and Phase 8 `includeIf`.

- `display-sync`, `screenshot` — macOS-native, moved verbatim
- `tmux-sessionizer` — paths remapped; **also fixed a latent bug**: it now
  filters roots to those that exist before calling `find`, which previously
  printed errors into the fzf list. Falls back to `attach-session` when run
  outside tmux.
- `dir-selector.sh` — paths remapped, `~/Pictures/screenshots` dropped
  (screenshot is clipboard-only now). Verified it creates the tree.

### [x] 11. Editor — nvim BUILT (activation pending)
`.config/nvim/` -> `dotfiles/nvim/` (22 files). Remarkably portable: exactly
**one** Linux path in the whole config — obsidian.nvim's workspace, remapped
to `~/src/github.com/personal/second_brain`.

`neovim 0.12.4` satisfies the treesitter `main` branch requirement (0.12+).

**Deployed with `mkOutOfStoreSymlink`, not a store symlink.** lazy.nvim
rewrites `lazy-lock.json` on `:Lazy update`, and store paths are read-only,
so a normal home.file would make plugin updates fail. `~/.config/nvim` now
points at the repo working tree, so the files stay writable and lock changes
show up as a git diff. This is the one config deliberately not read-only.

`gnumake` added to packages — telescope-fzf-native has `build = 'make'`,
which previously relied on Xcode CLT being present.

`lazy-lock.json` carried verbatim; verified 0 plugins differ from the
ubuntu-config commit.

Also restored in `.zshrc` (deferred from Phase 5, unblocked by the Phase 7
layout): `SB_DIR`/`DOTFILE_DIR`/`HOMELAB_DIR`/`BLOG_DIR`, the
`sb`/`dof`/`homelab`/`blog` aliases, and the zk `SB_PATH`/`BLOG_PATH`
exports — all remapped to `~/src/...`. SB_PATH matches the obsidian
workspace.

Note: 37 plugins are already cloned into `~/.local/share/nvim/lazy`, but 11
sit on newer commits than the lock. Run `:Lazy restore` to snap them to the
pinned versions.

### [x] 12. Claude + opencode — BUILT (activation pending)
`.config/claude` -> `dotfiles/claude`, `.config/opencode` -> `dotfiles/opencode`.

**statusline.sh had a real macOS break:** `date -d` is GNU-only and fails
with "illegal option -- d", so every rate-limit countdown was dead. Rewritten
to BSD `date -j -u -f`, keeping a `gdate` branch in case Homebrew coreutils
ever appears.

**Rejected the coreutils approach** (originally chosen) after testing:
- Nix's coreutils provides `date`, **not** `gdate` — the g-prefix is a
  Homebrew convention, so it would not have fixed anything
- putting GNU coreutils on PATH shadows BSD `ls`, and GNU `-G` means
  `--no-group` where BSD `-G` means colorize — it would have silently
  broken the `alias ls='ls -G'` from Phase 5

`jq` declared (statusline.sh depends on it; macOS ships /usr/bin/jq but
undeclared).

CLAUDE.md kept, all 36 `/home/mahakal` lines remapped to `~/src/...`.
Employer/repo names remain public — unchanged from ubuntu-config.
No real secrets: the `sk-ant-...` is a placeholder.

Deployment: the three `~/.claude/` files use `mkOutOfStoreSymlink` because
Claude Code rewrites settings.json via /config. opencode skills are a normal
store symlink (read-only content).

Verified statusline end-to-end on three input shapes — full rate limits
(countdowns render), no rate limits, and `{}` — none crash.

### [ ] 13. Cleanup
Delete `.config/i3/`, `install.sh`, `ansible-setup-script/`, `.alacritty.toml`,
`.bashrc`, `scripts/linkAllFile.sh`. Rewrite `README.md` for macOS.

**Questions:** replace `install.sh` with a one-command bootstrap script?
