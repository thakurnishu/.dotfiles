{ username, ... }:
{
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/packages.nix
  ];

  # Determinate Nix manages the daemon and /etc/nix/nix.conf itself.
  # Without this, activation aborts with "Determinate detected".
  # Nix settings belong in /etc/nix/nix.custom.conf, not here.
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow packages with non-open-source licences. Currently needed by
  # terraform (BUSL 1.1) and claude-code (proprietary). Set globally, so
  # future unfree packages install without prompting.
  nixpkgs.config.allowUnfree = true;

  # Required for user-scoped system.defaults and homebrew activation.
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # ---- Touch ID for sudo -------------------------------------------------
  # `darwin-rebuild switch` needs sudo, and an agent has no TTY to type a
  # password into — so applying config is always a human handoff. Touch ID
  # makes that handoff a fingerprint instead of a password.
  #
  # This writes /etc/pam.d/sudo_local (macOS ships it empty, and preserves it
  # across OS updates — unlike /etc/pam.d/sudo, which gets overwritten).
  #
  # reattach is required for Touch ID to work INSIDE tmux: pam_tid is tied to
  # the bootstrap session, and tmux's server survives outside it, so without
  # this sudo silently falls back to a password prompt in every tmux pane.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Do not change after the first successful build; it guards against
  # backwards-incompatible nix-darwin changes.
  system.stateVersion = 6;
}
