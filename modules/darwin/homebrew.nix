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

      # Brave, WhatsApp, Teams and Stats were installed outside Homebrew.
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

      # --- adopted from manual installs ---------------------------------
      "brave-browser"
      "whatsapp"
      "microsoft-teams"
      "stats"
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
