#!/usr/bin/env bash
# Driver for this nix-darwin dotfiles repo.
#
# This repo has no "app" to launch -- the deliverable is the state of the
# machine. So "driving" it means: does it build, is what's on disk actually
# what the repo says, and did anyone forget to switch?
#
# Everything here is READ-ONLY except `switch` (which applies the config via
# sudo -- Touch ID, so the human just touches the sensor) and the *-reload
# subcommands, which tell a running program to re-read its config:
# aerospace-reload, herdr-reload, ghostty-reload, tmux-reload. Everything else
# is safe to run anytime.
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
HERDR=/run/current-system/sw/bin/herdr

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

# ------------------------------------------------------ ghostty-reload -----
# Ghostty caches its config at launch, like AeroSpace and herdr. It has no
# reload subcommand -- the documented trigger is SIGUSR2 to the running
# process. Send ONLY SIGUSR2: Ghostty installs no handler for the other
# signals, so anything else terminates it, and since every herdr session and
# agent lives inside these windows that would take the whole desktop down.
#
# NOT everything reloads. Keybinds, theme and font changes apply on the spot;
# `background-opacity` does not -- on macOS the window's alpha is fixed when
# the window is created, so a changed VALUE needs a full quit (cmd+Q, not just
# closing a window). Toggling the configured opacity on and off at runtime is
# a separate thing, bound to cmd+shift+T in dotfiles/ghostty/config.
cmd_ghostty_reload() {
    head_ "ghostty reload (SIGUSR2)"
    if ! pgrep -x ghostty >/dev/null 2>&1; then
        warn "ghostty is not running -- nothing to reload"
        return 0
    fi
    if pkill -USR2 -x ghostty; then
        pass "SIGUSR2 sent"
        echo "       keybinds/theme/font apply now; a changed background-opacity"
        echo "       VALUE still needs a full restart (cmd+Q)"
    else
        fail "could not signal ghostty"
    fi
}

# ---------------------------------------------------------- tmux-reload -----
# tmux caches config in its SERVER, the same shape as AeroSpace and herdr, and
# like herdr there can be more than one -- one server per socket. A bare
# `tmux source-file` only reaches the default socket, so iterate.
#
# Sockets live under TMUX_TMPDIR or /tmp -- NOT $TMPDIR. On macOS those are
# different directories (/private/tmp/tmux-501 vs /var/folders/...), so using
# $TMPDIR finds nothing and reports a false "nothing to reload".
#
# A socket FILE outlives its server, so liveness is `has-session`, not
# `test -S`. Measured on this machine with no tmux running: the socket was
# still sitting there from a previous server.
#
# ASYMMETRIC, and this is the part that surprises: source-file only ever
# APPLIES settings. tmux has no "unset on re-source", so uncommenting a line
# and reloading works, while commenting one OUT and reloading does nothing --
# that needs `tmux kill-server` (which kills every session) or a fresh server.
cmd_tmux_reload() {
    head_ "tmux config reload"
    if ! command -v tmux >/dev/null 2>&1; then
        warn "tmux not installed, skipped"
        return 0
    fi

    local dir sock live=0
    dir="${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)"
    if [[ ! -d "$dir" ]]; then
        warn "no tmux server running, nothing to reload"
        return 0
    fi

    for sock in "$dir"/*; do
        [[ -S "$sock" ]] || continue
        tmux -S "$sock" has-session >/dev/null 2>&1 || continue
        live=1
        if tmux -S "$sock" source-file "$HOME/.tmux.conf" 2>/dev/null; then
            pass "reloaded server: $(basename "$sock")"
        else
            warn "reload failed for server: $(basename "$sock")"
        fi
    done

    if [[ $live -eq 0 ]]; then
        warn "no tmux server running, nothing to reload"
        return 0
    fi
    echo "       source-file only ADDS settings; removing one needs a new"
    echo "       server (tmux kill-server)"
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
        cmd_herdr_reload
        cmd_ghostty_reload
        cmd_tmux_reload
        echo
        echo "  .zshrc changes need a new shell:  exec zsh"
    else
        fail "switch failed, or Touch ID was declined/timed out"
        echo "       Run it yourself with the ! prefix if this keeps failing:"
        echo "         sudo darwin-rebuild switch --flake $FLAKE"
    fi
}

# ------------------------------------------------------- herdr-reload -----
# herdr caches config in its server, like AeroSpace does. Unlike AeroSpace
# there can be SEVERAL servers -- one per session -- and a bare
# `herdr server reload-config` only reaches the default one. Since
# session-picker puts real work in the named `work` and `personal` sessions,
# reloading only default would silently do nothing useful. So iterate.
#
# Note herdr/config.toml is an out-of-store symlink, so its contents change
# the moment you edit the repo file -- no switch required. This reload is
# what makes a running server notice.
cmd_herdr_reload() {
    head_ "herdr config reload"
    if [[ ! -x "$HERDR" ]]; then
        warn "herdr not installed, skipped"
        return 0
    fi

    local names
    names=$("$HERDR" session list --json 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for s in d.get("sessions", []):
    if s.get("running"):
        print(s["name"])
' 2>/dev/null)

    if [[ -z "$names" ]]; then
        warn "no herdr server running, nothing to reload"
        return 0
    fi

    local n out
    while IFS= read -r n; do
        [[ -n "$n" ]] || continue
        # "default" is a display label; that session has no name internally,
        # so it is addressed by omitting --session entirely.
        if [[ "$n" == "default" ]]; then
            out=$("$HERDR" server reload-config 2>&1)
        else
            out=$("$HERDR" --session "$n" server reload-config 2>&1)
        fi
        if [[ "$out" == *'"status":"applied"'* ]]; then
            pass "reloaded session: $n"
        else
            warn "reload failed for session $n: ${out:0:80}"
        fi
    done <<< "$names"
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
    herdr-reload)     cmd_herdr_reload;;
    tmux-reload)      cmd_tmux_reload;;
    ghostty-reload)   cmd_ghostty_reload;;
    switch)           cmd_switch "$@";;
    *)
        echo "usage: $(basename "$0") {check|doctor|lint|build|pending|links|stale|drift|zsh|aerospace|aerospace-reload|herdr-reload|ghostty-reload|tmux-reload|switch}"
        exit 2;;
esac
exit $FAILED
