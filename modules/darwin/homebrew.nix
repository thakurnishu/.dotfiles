# GUI applications via Homebrew casks — Phase 3.
#
# GUI apps come from Homebrew rather than Nix: .app bundles don't work well
# from the Nix store, and Nix-installed GUI apps can't be configured through
# their own UI. nix-darwin drives `brew bundle`, so the list stays declarative.
#
# This module does NOT install Homebrew itself — brew must already exist.
{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      # "none" = never remove anything not listed here. Anything you
      # `brew install` by hand survives rebuilds. Change to "check" to be
      # warned about drift, or "uninstall" to enforce this list strictly.
      cleanup = "none";

      # Keep rebuilds fast and deterministic: only install what's missing.
      # Run `brew update && brew upgrade` yourself when you want new versions.
      autoUpdate = false;
      upgrade = false;

      # Brave, WhatsApp, Teams, Stats and Affinity were installed outside
      # Homebrew (Affinity from its DMG).
      # --adopt makes brew take ownership of the existing .app in place
      # instead of erroring or re-downloading it.
      extraEnv = {
        HOMEBREW_CASK_OPTS = "--adopt";
      };
    };

    casks = [
      # --- already brew-managed -----------------------------------------
      "aerospace" # tiling WM, replaces i3
      "ghostty" # terminal, replaces alacritty
      # claude-code moved to Nix in Phase 4 (modules/darwin/packages.nix).
      # If the old cask is still installed, remove it once with:
      #   brew uninstall --cask claude-code

      # --- required by the Ghostty config (Phase 6) ---------------------
      # No Nerd Font is installed on this Mac; without this Ghostty would
      # silently fall back to a default font.
      "font-jetbrains-mono-nerd-font"

      # --- screenshots --------------------------------------------------
      # Driven entirely through its shottr:// URL scheme from
      # ~/.local/bin/screenshot, so its own global hotkeys can stay off and
      # AeroSpace remains the single source of truth for keybindings.
      # Needs Screen Recording permission; Accessibility too for scrolling
      # capture and window detection.
      "shottr"

      # --- adopted from manual installs ---------------------------------
      "brave-browser"
      "whatsapp"
      "microsoft-teams"
      "stats"

      # Canva's unified Affinity (bundle id com.canva.affinity), NOT the old
      # affinity-photo/-designer/-publisher casks — those are Affinity 2,
      # discontinued upstream and due to be disabled on 2026-10-30.
      "affinity"
    ];

    # CLI tools live in modules/darwin/packages.nix (Nix), not here.
    # displayplacer is the exception: it is NOT in nixpkgs, so Homebrew is
    # the only declarative option. ~/.local/bin/display-sync depends on it
    # (bound to alt-shift-s in AeroSpace).
    brews = [
      "displayplacer"
    ];

    masApps = { };
  };
}
