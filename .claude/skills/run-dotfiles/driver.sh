#!/usr/bin/env bash
# Driver for this nix-darwin dotfiles repo.
#
# This repo has no "app" to launch -- the deliverable is the state of the
# machine. So "driving" it means: does it build, is what's on disk actually
# what the repo says, and did anyone forget to switch?
#
# Everything here is READ-ONLY except `switch` (which applies the config via
# sudo -- Touch ID, so the human just touches the sensor) and `aerospace-reload`
# (which reloads the running WM). Everything else is safe to run anytime.
#
# Usage:  .claude/skills/run-dotfiles/driver.sh [subcommand]
# Run with no subcommand for the full preflight.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# When run from a feature worktree, REPO is that worktree -- but the
# out-of-store links for nvim and .claude/* deliberately stay pinned to the
# main checkout (you do not want your editor config following a throwaway
# branch). `links` must accept both roots or it reports four false failures.
MAIN_REPO="$(git -C "$REPO" worktree list 2>/dev/null | head -1 | awk '{print $1}')"
MAIN_REPO="${MAIN_REPO:-$REPO}"
FLAKE="$REPO#macbook"
ATTR=".#darwinConfigurations.macbook"
USER_NAME="$(id -un)"

# Homebrew is not on PATH in every context (nix-darwin activation, non-login
# shells, agent sandboxes). Resolve it explicitly.
BREW=""
for c in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$c" ]] && { BREW="$c"; break; }
done
AEROSPACE=/opt/homebrew/bin/aerospace

FAILED=0
pass() { printf '  \033[32mok\033[0m   %s\n' "$*"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAILED=1; }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$*"; }
head_() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

# Resolve a symlink chain all the way down. macOS `readlink -f` works on
# current versions; python3 is the fallback (it is in packages.nix anyway).
realpath_() {
    readlink -f "$1" 2>/dev/null \
        || python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"
}

# ---------------------------------------------------------------- lint -----
# Syntax-only. Catches the class of error that would otherwise brick a shell
# or the WM *after* a successful switch -- nix happily deploys a .zshrc with a
# syntax error, because to nix it is just an opaque file.
cmd_lint() {
    head_ "lint"

    if zsh -n "$REPO/dotfiles/.zshrc" 2>/dev/null; then
        pass ".zshrc parses"
    else
        fail ".zshrc has a syntax error:"
        zsh -n "$REPO/dotfiles/.zshrc"
    fi

    for f in "$REPO"/dotfiles/.local/bin/*; do
        [[ -f "$f" ]] || continue
        if bash -n "$f" 2>/dev/null; then
            pass "$(basename "$f") parses"
        else
            fail "$(basename "$f") has a syntax error:"
            bash -n "$f"
        fi
    done

    # AeroSpace ships no validate-a-file command, so this only proves the TOML
    # is well formed -- not that the keys are valid AeroSpace options.
    if python3 -c "import tomllib,sys;tomllib.load(open(sys.argv[1],'rb'))" \
        "$REPO/dotfiles/.aerospace.toml" 2>/dev/null; then
        pass ".aerospace.toml is valid TOML"
    else
        fail ".aerospace.toml is not valid TOML"
    fi

    if python3 -c "import tomllib,sys;tomllib.load(open(sys.argv[1],'rb'))" \
        "$REPO/dotfiles/starship.toml" 2>/dev/null; then
        pass "starship.toml is valid TOML"
    else
        fail "starship.toml is not valid TOML"
    fi
}

# --------------------------------------------------------------- build -----
# No sudo: this only realises the closure, it does not activate it.
cmd_build() {
    head_ "build"
    local out
    if out=$(cd "$REPO" && nix build --no-link --print-out-paths \
             "$ATTR.system" 2>/dev/null); then
        pass "system closure builds"
        echo "       $out"
        echo "$out"  >"${TMPDIR:-/tmp}/dotfiles-built-system"
    else
        fail "build failed -- rerun to see the error:"
        echo "       cd $REPO && nix build $ATTR.system"
        (cd "$REPO" && nix build --no-link "$ATTR.system" 2>&1 | tail -20)
    fi
}

# ------------------------------------------------------------- pending -----
# THE recurring trap: edit a config, forget to switch, then debug a keybinding
# that was never deployed. Compares the built closure to the live one.
cmd_pending() {
    head_ "pending switch?"
    local built current
    built=$(cd "$REPO" && nix build --no-link --print-out-paths \
            "$ATTR.system" 2>/dev/null)
    current=$(realpath_ /run/current-system)

    if [[ -z "$built" ]]; then
        fail "cannot build; see 'build'"
        return
    fi
    if [[ "$built" == "$current" ]]; then
        pass "live system matches the repo -- nothing to switch"
    else
        fail "repo differs from the running system. Apply with:"
        echo "       sudo darwin-rebuild switch --flake $FLAKE"
        echo "       built:   $built"
        echo "       current: $current"
    fi
}

# --------------------------------------------------------------- links -----
# Asks nix for the authoritative list of deployed files rather than hardcoding
# one (a hardcoded list silently rots as modules/home/default.nix grows), then
# checks each one is (a) a symlink, (b) of the right KIND, and (c) actually
# carrying the repo's current content.
#
# The two kinds are not cosmetic -- README documents why. nvim and ~/.claude/*
# MUST stay writable because lazy.nvim and Claude Code write to them; a
# read-only store path makes those saves fail.
cmd_links() {
    head_ "deployed symlinks"
    local json
    json=$(cd "$REPO" && nix eval --json \
        "$ATTR.config.home-manager.users.$USER_NAME.home.file" \
        --apply 'fs: builtins.map (f: f.target) (builtins.attrValues fs)' \
        2>/dev/null)
    if [[ -z "$json" ]]; then
        fail "could not read the file map from nix"
        return
    fi

    local t live real
    while IFS= read -r t; do
        # home-manager's own bookkeeping, not our dotfiles.
        case "$t" in
            .cache/.keep|.local/state/.keep|Library/Fonts/*|Applications/*) continue;;
        esac
        live="$HOME/$t"
        if [[ ! -L "$live" ]]; then
            [[ -e "$live" ]] && fail "$t exists but is NOT a symlink (hand-edited?)" \
                             || fail "$t is missing -- switch not applied?"
            continue
        fi
        real=$(realpath_ "$live")
        case "$real" in
            "$REPO"/*|"$MAIN_REPO"/*)
                if [[ -w "$real" ]]; then
                    local where="repo"
                    [[ "$real" == "$MAIN_REPO"/* && "$real" != "$REPO"/* ]] && where="main checkout"
                    pass "$t -> $where (out-of-store, writable)"
                else
                    fail "$t resolves to the repo but is not writable"
                fi
                ;;
            /nix/store/*)
                # Content freshness is checked separately by `stale`.
                if [[ -w "$real" ]]; then
                    fail "$t is in the store but WRITABLE (unexpected)"
                else
                    pass "$t -> store (read-only)"
                fi
                ;;
            *)  fail "$t resolves outside both the store and the repo: $real";;
        esac
    done < <(echo "$json" | python3 -c 'import json,sys;[print(x) for x in json.load(sys.stdin)]')
}

# --------------------------------------------------------------- stale -----
# Store symlinks are snapshots. If you edit dotfiles/ and do not switch, the
# live file still holds the old bytes -- this diffs them.
cmd_stale() {
    head_ "repo vs deployed content"
    local pairs=(
        ".zshrc:dotfiles/.zshrc"
        ".tmux.conf:dotfiles/.tmux.conf"
        ".gitconfig:dotfiles/.gitconfig"
        ".aerospace.toml:dotfiles/.aerospace.toml"
        ".config/ghostty/config:dotfiles/ghostty/config"
        ".config/starship.toml:dotfiles/starship.toml"
        ".local/bin/screenshot:dotfiles/.local/bin/screenshot"
        ".local/bin/display-sync:dotfiles/.local/bin/display-sync"
        ".local/bin/tmux-sessionizer:dotfiles/.local/bin/tmux-sessionizer"
        ".local/bin/dir-selector.sh:dotfiles/.local/bin/dir-selector.sh"
    )
    local p live repo
    for p in "${pairs[@]}"; do
        live="$HOME/${p%%:*}"
        repo="$REPO/${p##*:}"
        [[ -e "$live" && -e "$repo" ]] || { warn "${p%%:*} missing, skipped"; continue; }
        if cmp -s "$live" "$repo"; then
            pass "${p%%:*} is current"
        else
            fail "${p%%:*} differs from the repo -- switch needed"
        fi
    done
}

# --------------------------------------------------------------- drift -----
# `onActivation.cleanup = "none"` means brew NEVER removes anything, so casks
# installed by hand are invisible to the repo. This surfaces both directions.
cmd_drift() {
    head_ "homebrew drift"
    if [[ -z "$BREW" ]]; then
        warn "brew not found; skipping"
        return
    fi
    local declared installed
    declared=$(cd "$REPO" && nix eval --json "$ATTR.config.homebrew.casks" 2>/dev/null \
        | python3 -c 'import json,sys;[print(x if isinstance(x,str) else x.get("name","")) for x in json.load(sys.stdin)]' | sort)
    installed=$("$BREW" list --cask 2>/dev/null | sort)

    local missing extra
    missing=$(comm -23 <(echo "$declared") <(echo "$installed"))
    extra=$(comm -13 <(echo "$declared") <(echo "$installed"))

    if [[ -z "$missing" ]]; then
        pass "every declared cask is installed"
    else
        fail "declared but NOT installed (run the switch):"
        echo "$missing" | sed 's/^/       /'
    fi
    if [[ -z "$extra" ]]; then
        pass "no undeclared casks"
    else
        warn "installed but NOT in homebrew.nix (cleanup=none keeps these):"
        echo "$extra" | sed 's/^/       /'
    fi
}

# ----------------------------------------------------------------- zsh -----
# Loads the REPO copy of .zshrc in a throwaway ZDOTDIR, so you can test shell
# changes without switching and without touching your live shell.
cmd_zsh() {
    head_ "zsh (repo copy, throwaway ZDOTDIR)"
    local d
    d=$(mktemp -d)
    cp "$REPO/dotfiles/.zshrc" "$d/.zshrc"
    echo "  key bindings:"
    ZDOTDIR="$d" zsh -i -c 'bindkey' 2>/dev/null \
        | grep -E '"\^[FLRT]"' | sed 's/^/       /'
    echo "  startup errors (empty is good):"
    ZDOTDIR="$d" zsh -i -c 'true' 2>&1 \
        | grep -v "can't change option: zle" | sed 's/^/       /'
    rm -rf "$d"
}

# ----------------------------------------------------------- aerospace -----
# AeroSpace reads its config once at startup. After a switch rewrites
# ~/.aerospace.toml the RUNNING instance is still on the old one until it is
# reloaded -- so a new binding "does nothing" and falls through to the app.
cmd_aerospace() {
    head_ "aerospace (running instance)"
    if [[ ! -x "$AEROSPACE" ]]; then
        warn "aerospace not installed; skipping"
        return
    fi
    echo "  version: $("$AEROSPACE" --version 2>&1 | head -1)"
    echo "  monitors:"
    "$AEROSPACE" list-monitors 2>&1 | sed 's/^/       /'
    echo "  screenshot bindings the running instance actually has:"
    local k
    for k in alt-shift-p alt-shift-o ctrl-alt-shift-p; do
        printf '       %-18s %s\n' "$k" \
            "$("$AEROSPACE" config --get "mode.main.binding.$k" 2>&1)"
    done
    echo
    echo "  if a binding is missing after a switch:  $AEROSPACE reload-config"
}

cmd_aerospace_reload() {
    head_ "aerospace reload-config"
    "$AEROSPACE" reload-config && pass "reloaded" || fail "reload failed"
}

# -------------------------------------------------------------- doctor -----
cmd_doctor() {
    head_ "prerequisites"
    local t
    for t in nix darwin-rebuild git python3 zsh; do
        if command -v "$t" >/dev/null 2>&1; then
            pass "$t  ($(command -v "$t"))"
        else
            fail "$t is missing"
        fi
    done
    [[ -n "$BREW" ]] && pass "brew ($BREW)" || fail "brew is missing (install-macos.sh installs it)"
    [[ -x "$AEROSPACE" ]] && pass "aerospace ($AEROSPACE)" || warn "aerospace not installed"
}

# -------------------------------------------------------------- switch -----
# An agent CAN run this. Touch ID (security.pam.services.sudo_local.touchIdAuth,
# see hosts/macbook/default.nix) authenticates through the Security framework,
# not the terminal -- pam_tid needs no TTY, so sudo works from a non-interactive
# tool call and the human's whole job is to touch the sensor.
#
# `sudo -n` still fails, and that is expected: -n explicitly forbids prompting.
# Do not use it to decide whether this will work.
#
# Falls back to printing the command if authentication does not happen.
cmd_switch() {
    head_ "apply"
    local built current
    built=$(cd "$REPO" && nix build --no-link --print-out-paths \
            "$ATTR.system" 2>/dev/null)
    current=$(realpath_ /run/current-system)

    if [[ -n "$built" && "$built" == "$current" && "${2:-}" != "force" ]]; then
        pass "already applied -- nothing to switch"
        echo "       (re-apply anyway with: $(basename "$0") switch force)"
        return 0
    fi

    echo "  running: sudo darwin-rebuild switch --flake $FLAKE"
    printf '  \033[1mTOUCH THE FINGERPRINT SENSOR when macOS asks\033[0m\n\n'

    if sudo darwin-rebuild switch --flake "$FLAKE"; then
        pass "switch applied"
        # AeroSpace caches its config at startup; a switch rewrites the file but
        # the running instance keeps the old bindings until it is told to reload.
        if [[ -x "$AEROSPACE" ]]; then
            "$AEROSPACE" reload-config 2>/dev/null \
                && pass "aerospace reloaded" \
                || warn "aerospace reload failed (is it running?)"
        fi
        echo
        echo "  .zshrc changes need a new shell:  exec zsh"
    else
        fail "switch failed, or Touch ID was declined/timed out"
        echo "       Run it yourself with the ! prefix if this keeps failing:"
        echo "         sudo darwin-rebuild switch --flake $FLAKE"
    fi
}

cmd_check() {
    cmd_doctor
    cmd_lint
    cmd_build
    cmd_pending
    cmd_links
    cmd_stale
    cmd_drift
    head_ "result"
    if [[ $FAILED -eq 0 ]]; then
        printf '  \033[32mall checks passed\033[0m\n\n'
    else
        printf '  \033[31msome checks failed (see FAIL above)\033[0m\n\n'
    fi
    return $FAILED
}

case "${1:-check}" in
    check)            cmd_check;;
    doctor)           cmd_doctor;;
    lint)             cmd_lint;;
    build)            cmd_build;;
    pending)          cmd_pending;;
    links)            cmd_links;;
    stale)            cmd_stale;;
    drift)            cmd_drift;;
    zsh)              cmd_zsh;;
    aerospace)        cmd_aerospace;;
    aerospace-reload) cmd_aerospace_reload;;
    switch)           cmd_switch "$@";;
    *)
        echo "usage: $(basename "$0") {check|doctor|lint|build|pending|links|stale|drift|zsh|aerospace|aerospace-reload|switch}"
        exit 2;;
esac
exit $FAILED
