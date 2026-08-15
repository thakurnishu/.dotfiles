#!/usr/bin/env bash
# Bootstrap this config on a fresh Mac. macOS counterpart to install.sh
# (which is Ubuntu-only: apt + ansible).
#
#   ./install-macos.sh
#
# Idempotent — safe to re-run. Each step is skipped if already done.

set -euo pipefail

REPO="${HOME}/.dotfiles"
FLAKE="${REPO}#macbook"

log() { printf '\n\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m warning:\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------- 1. CLT ---
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools"
  xcode-select --install
  echo "Finish the GUI installer, then re-run this script."
  exit 1
fi

# ----------------------------------------------------------- 2. Homebrew ---
# Needed before Nix: nix-darwin's homebrew module drives an existing brew
# install, it does not bootstrap one. GUI apps come from casks because .app
# bundles don't work well from the Nix store.
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  log "Homebrew already installed"
fi

# ----------------------------------------------------------------- 3. Nix ---
# Determinate installer: flakes on by default, clean uninstaller.
if [ ! -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  log "Installing Determinate Nix"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install
else
  log "Nix already installed"
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# ---------------------------------------------------------------- 4. repo ---
if [ ! -d "$REPO" ]; then
  log "Cloning dotfiles"
  git clone https://github.com/thakurnishu/.dotfiles.git "$REPO"
  git -C "$REPO" checkout macos-config
  git -C "$REPO" remote set-url origin git@github.com:thakurnishu/.dotfiles.git
else
  log "Repo already present at $REPO"
fi

# ------------------------------------------------------------- 5. activate ---
# darwin-rebuild doesn't exist until the first switch, so bootstrap it from
# the flake. Subsequent rebuilds use the installed, pinned binary.
if command -v darwin-rebuild >/dev/null 2>&1; then
  log "Rebuilding (darwin-rebuild)"
  sudo darwin-rebuild switch --flake "$FLAKE"
else
  log "First activation (bootstrapping darwin-rebuild via nix run)"
  sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "$FLAKE"
fi

# ---------------------------------------------------------------- 6. notes ---
log "Done. Remaining manual steps:"
cat <<'EOF'
  * Log out and back in — `_HIHideMenuBar` and `spaces.spans-displays`
    are only read at session start.
  * Grant AeroSpace Accessibility permission:
      System Settings -> Privacy & Security -> Accessibility
  * Grant Ghostty Screen Recording if you want `screenshot` to work when
    run from a terminal (it already works via the AeroSpace keybinding).
  * ~/.ssh/config is NOT managed here (this repo is public). Recreate it
    and copy your keys across by hand.
  * In nvim, run :Lazy restore to pin plugins to lazy-lock.json.
  * `colima start` before using docker or kind.
EOF
