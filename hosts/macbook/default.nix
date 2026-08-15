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

  # Do not change after the first successful build; it guards against
  # backwards-incompatible nix-darwin changes.
  system.stateVersion = 6;
}
