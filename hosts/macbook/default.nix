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
