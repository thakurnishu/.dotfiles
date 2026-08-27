# .dotfiles — macOS

macOS configuration managed with [nix-darwin](https://github.com/nix-darwin/nix-darwin)
and [home-manager](https://github.com/nix-community/home-manager), ported from
the `ubuntu-config` branch.

Branches:
- **`macos-config`** (this one) — Apple Silicon, macOS 26
- `ubuntu-config` — the Ubuntu/i3 original
- `main` — older, minimal

## Setup

```bash
git clone https://github.com/thakurnishu/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && git checkout macos-config
./install-macos.sh
```

Installs Xcode CLT, Homebrew, Determinate Nix, then activates. Idempotent.

## Rebuilding

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles#macbook
```

Other useful commands:

```bash
sudo darwin-rebuild build --flake ~/.dotfiles#macbook   # check it compiles
darwin-rebuild --list-generations
sudo darwin-rebuild --rollback                          # undo last switch
nix flake update                                        # bump package versions
```

## Layout

```
flake.nix                    nixpkgs-unstable, aarch64-darwin
hosts/macbook/default.nix    nix.enable=false (Determinate owns the daemon)
modules/
  darwin/system.nix          macOS defaults (dock, finder, key repeat…)
  darwin/homebrew.nix        GUI apps as casks + displayplacer
  darwin/packages.nix        CLI packages
  home/default.nix           dotfile deployment
dotfiles/                    the actual config files
  .zshrc  .tmux.conf  .gitconfig  .aerospace.toml  starship.toml
  ghostty/config
  gitwork/<org>              git identity -> ~/.gitwork-<org>
  nvim/  claude/  opencode/
  .local/bin/{screenshot,display-sync,tmux-sessionizer,dir-selector.sh}
```

Kept for reference, not used on macOS: `install.sh`, `ansible-setup-script/`,
`scripts/linkAllFile.sh` (home-manager replaces the last one).

## Making changes

Edit the file under `dotfiles/`, then rebuild. **Not** the copy in `$HOME` —
those are symlinks.

Two kinds of symlink, and the difference matters:

| Config | Link type | Editable in place? |
|---|---|---|
| `.zshrc`, `.tmux.conf`, `.gitconfig`, `.aerospace.toml`, ghostty, starship, opencode | Nix store | **No** — read-only (0444) |
| `nvim/`, `~/.claude/{settings.json,statusline.sh,CLAUDE.md}` | out-of-store | Yes — points at this repo |

The out-of-store ones exist because their apps *write* to them: `lazy.nvim`
rewrites `lazy-lock.json`, and Claude Code rewrites `settings.json` when you
use `/config`. A read-only store path would make those saves fail.

## Keybindings

AeroSpace replaces i3. `alt` = i3's `$mod`; `cmd` drives the second monitor.

| Keys | Action |
|---|---|
| `alt-1/2/3` | workspaces 1–3 (main display) |
| `cmd-1/2/3` | workspaces 4–6 (secondary display) |
| `alt-shift-<n>` / `cmd-shift-<n>` | move window to that workspace |
| `alt-h/j/k/l` | focus left/down/up/right |
| `alt-shift-h/j/k/l` | move window |
| `alt-t` / `alt-v` | split horizontal / vertical |
| `alt-f` | fullscreen |
| `alt-s` / `alt-w` | stacking / tabbed (accordion) |
| `alt-e` | toggle split orientation |
| `alt-shift-space` | toggle floating |
| `alt-shift-q` | close window |
| `alt-enter` | new Ghostty window |
| `alt-r` | resize mode (`h/j/k/l`, Esc to exit) |
| `alt-shift-c` | reload AeroSpace config |
| `alt-shift-s` | re-apply display arrangement (displayplacer) |
| `alt-shift-p` | region screenshot → clipboard |
| `ctrl-alt-shift-p` | full screenshot → clipboard |
| `ctrl-alt-←/→` | focus monitor |
| `alt-shift-backspace` | sleep |

Shell: `Ctrl-F` opens the fzf directory jumper, `Ctrl-L` clears.
`cmd-1/2/3` are taken from Brave — its numbered tab shortcuts no longer work.

## Notes

- **Code lives in `~/src/github.com/{personal,work}`** (Linux used
  `~/Desktop/src/...`). The `sb`/`dof`/`homelab`/`blog` aliases, zk paths,
  obsidian workspace and gitconfig `includeIf` all follow this.
- **`~/.ssh/config` is tracked, but only the half that is safe to publish.**
  This repo is public, so the file here holds the github accounts and the
  global defaults and nothing else. The hosts come from two `Include`s:
  `~/.ssh/config.homelab`, a symlink into the (also public) homelab repo,
  carrying only RFC1918 addresses that repo already exposes; and
  `~/.ssh/config.local`, untracked and machine-local, which is where the
  EC2 host and the employer GitLab live. On a new machine the tracked half
  arrives with home-manager and `config.local` is the part to recreate by
  hand, along with the keys.
- **`colima start`** before using docker or kind; macOS has no native Docker
  daemon.
- GUI apps come from Homebrew casks rather than Nix: `.app` bundles don't
  work well from the store, and Nix-installed GUI apps can't be configured
  through their own UI.
- `PORTING-PLAN.md` records the full Ubuntu → macOS port, phase by phase,
  including what was dropped and why.
