---
name: run-dotfiles
description: Build, verify, apply and troubleshoot this nix-darwin dotfiles repo. Use when asked to run, build, check, test, lint, rebuild, switch, or apply the dotfiles/system config; to add a package, cask or keybinding; to debug why a config change "isn't working"; or to check whether the live machine matches the repo.
---

# run-dotfiles

This repo has no app to launch. The deliverable is **the state of the machine** —
nix-darwin + home-manager build a system closure and symlink configs into `$HOME`.
So "running" it means: does it build, does the live machine match the repo, and
did anyone forget to apply it.

All of that is wrapped in one driver:

```
.claude/skills/run-dotfiles/driver.sh
```

Paths below are relative to the repo root (`~/.dotfiles`).

**The one thing an agent cannot do:** `darwin-rebuild switch` requires `sudo`,
which requires a real terminal. Everything else here is agent-runnable and
read-only. Hand the switch to the human.

## Prerequisites

Already present on this machine; `driver.sh doctor` verifies them. On a fresh
box `./install-macos.sh` installs Xcode CLT, Homebrew and Determinate Nix.

Homebrew is **not on `PATH` in agent shells** — call `/opt/homebrew/bin/brew`
explicitly. The driver does this for you.

## Run (agent path)

```bash
.claude/skills/run-dotfiles/driver.sh          # full preflight; exit 0 = clean
```

Runs `doctor`, `lint`, `build`, `pending`, `links`, `stale`, `drift`. Takes
~30s warm. Individual subcommands:

| Subcommand | What it proves |
|---|---|
| `doctor` | nix, darwin-rebuild, brew, aerospace, python3, zsh are present |
| `lint` | `.zshrc` + `.local/bin/*` parse; the TOMLs are well formed |
| `build` | the system closure builds (no sudo, no activation) |
| `pending` | **the live system matches the repo** — catches "forgot to switch" |
| `links` | every deployed file is a symlink of the *right kind* (see Gotchas) |
| `stale` | deployed file contents still match `dotfiles/` |
| `drift` | declared casks vs actually-installed casks, both directions |
| `zsh` | loads the **repo** `.zshrc` in a throwaway `ZDOTDIR`, dumps keybindings |
| `aerospace` | what the **running** WM actually has bound right now |
| `aerospace-reload` | re-read `~/.aerospace.toml` (the running instance is stale after a switch) |
| `switch` | prints the sudo command for the human — deliberately does not run it |

`lint`, `pending`, `stale` and `drift` were each verified to **fail** on a
deliberately broken repo, not just to print ok.

### Making a change

```bash
# 1. edit the file under dotfiles/ -- NEVER the copy in $HOME (read-only symlink)
# 2. check before applying:
.claude/skills/run-dotfiles/driver.sh
# 3. hand to the human:
sudo darwin-rebuild switch --flake ~/.dotfiles#macbook
# 4. reload the consumer that caches its config:
/opt/homebrew/bin/aerospace reload-config    # keybinding changes
exec zsh                                     # or a new tab, for .zshrc changes
```

Where things go: **CLI tools → Nix** (`modules/darwin/packages.nix`),
**GUI apps → Homebrew casks** (`modules/darwin/homebrew.nix`). One deliberate
exception, `displayplacer`, is a brew *formula* because it is not in nixpkgs.

## Run (human path)

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles#macbook        # apply
sudo darwin-rebuild --list-generations                        # needs sudo, see below
sudo darwin-rebuild --rollback                                # undo last switch
nix flake update                                              # bump pinned versions
```

`--list-generations` needs `sudo` despite being read-only — without it you get
`error: opening lock file "/nix/var/nix/profiles/system.lock": Permission denied`.
(`README.md` lists it without `sudo`; that does not work here.)

Not run while authoring this skill, so treat as documented-but-unverified:
`--rollback` and `nix flake update` — both mutate state.

## Gotchas

- **A successful switch is not the end.** AeroSpace reads its config **once at
  startup**. After a switch rewrites `~/.aerospace.toml`, the running instance
  still has the old bindings, so a new keybinding silently falls through to the
  focused app — e.g. `alt-shift-o` typing `Ø` instead of firing. Fix:
  `aerospace reload-config` (or `alt-shift-c`). Same shape for `.zshrc`:
  existing shells keep the old one until `exec zsh`.

- **Two kinds of symlink, and the difference is load-bearing.** Most configs are
  read-only Nix store symlinks. But `~/.config/nvim` and `~/.claude/{settings.json,
  statusline.sh,CLAUDE.md}` use `mkOutOfStoreSymlink` and point at the working
  tree, because **their apps write to them** — lazy.nvim rewrites
  `lazy-lock.json`, Claude Code rewrites `settings.json` on `/config`. A store
  path would make those saves fail. `driver.sh links` asserts each file is the
  correct kind; if you convert one by accident the failure is silent until an
  app tries to save.

- **Never edit the copy in `$HOME`.** It is 0444 in the store. Edit `dotfiles/`
  and switch. `driver.sh stale` catches the case where you edited the repo and
  forgot.

- **`cleanup = "none"`** (`homebrew.nix`) means brew never removes anything, so
  hand-installed casks are invisible to the repo forever. `driver.sh drift`
  surfaces them. Adopt one with
  `brew install --cask --adopt <name>` after adding it to `homebrew.nix` — that
  takes ownership of the existing `.app` in place instead of re-downloading.

- **Casks are `auto_updates`** and `homebrew.nix` sets `upgrade = false`, so the
  repo does **not** pin GUI app versions — those apps update themselves. Only
  the Nix packages are pinned (by `flake.lock`).

- **`bindkey -v` (vi mode) leaves `^R` unbound.** `history-incremental-search-backward`
  only exists in the emacs keymap, so `^R` fell through to `redisplay` and
  appeared dead. Now fixed by sourcing `fzf --zsh`, which must come **after**
  `compinit`.

- **Nix build noise is harmless**: "Git tree has uncommitted changes" and the
  `options.json` / `builtins.derivation` warning appear on every build. Ignore
  both.

- **The built closure path is the source of truth** for "is this applied?" —
  `driver.sh pending` compares `nix build --print-out-paths` against
  `readlink /run/current-system`. Two different hashes = not applied.

### macOS window-manager facts (measured on this machine)

- The built-in display reserves **28 pt** at the top as notch safe area
  (`NSScreen.safeAreaInsets.top`), *independent of the menu bar* — the external
  Dell, which actually owns the menu bar, loses nothing. AeroSpace tiles into
  `visibleFrame`, so that strip is unreachable. Negative `outer.top` gaps parse
  but macOS clamps the position: verified `-28` moved nothing while `+40` moved
  the window correctly. Only an app can place *its own* window there.

- **AeroSpace does not retile hidden workspaces.** Measuring a window on a
  non-visible workspace returns a stale frame. Focus the workspace first, or
  your measurements are meaningless.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| New keybinding does nothing, types a character instead | Running AeroSpace has stale config → `aerospace reload-config` |
| `.zshrc` change has no effect | Existing shell has the old rc → `exec zsh` or new tab |
| `Permission denied` writing `~/.zshrc` | It is a read-only store symlink. Edit `dotfiles/.zshrc`, then switch |
| `brew: command not found` in an agent shell | Use `/opt/homebrew/bin/brew` |
| `aerospace config --get gaps...` → "No value at key token 'gaps'" | Only `mode`/bindings are queryable; gaps are not exposed. Not an error |
| App installed by hand, not in repo | Add to `homebrew.nix`, then `brew install --cask --adopt <name>` |
| Activation fails "would be clobbered" | A real file sits where home-manager wants a symlink; `backupFileExtension = "hm-backup"` in `flake.nix` handles most cases |
| Activation aborts "Determinate detected" | `nix.enable = false` must stay set in `hosts/macbook/default.nix` |

## Known stale doc

`README.md:116` still references `PORTING-PLAN.md`, which was deleted in
`e906fd4`. Harmless, but it will send a reader looking for a file that is not
there.
