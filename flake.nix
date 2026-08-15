{
  description = "nishantsingh's macOS configuration (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "nishantsingh";
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          ./hosts/macbook

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # If a real file already exists where home-manager wants to
              # place one, rename it instead of aborting the whole switch.
              # Claude Code writes ~/.claude/settings.json on first run, which
              # would otherwise fail activation with "would be clobbered".
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit username; };
              users.${username} = import ./modules/home;
            };
          }
        ];
      };

      # Convenience alias so `darwin-rebuild switch --flake .` works too.
      darwinConfigurations.${username} = self.darwinConfigurations.macbook;
    };
}
