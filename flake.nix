{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.nixpkgs-staging-next.url = "nixpkgs/staging-next";

  outputs = inputs@{ self, nixpkgs, nixpkgs-staging-next }:
    let
      system = "x86_64-linux";
      overlay-staging-next = final: prev: {
        staging-next = nixpkgs-staging-next.legacyPackages.${prev.system};
      };
    in {
      nixosConfigurations = {
        dn = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-staging-next ];
            })
            # Add to regsitry so nixpkgs commands use system versions
            ({ pkgs, ... }: { nix.registry.nixpkgs.flake = inputs.nixpkgs; })
            ./common.nix
            ./hosts/dn/configuration.nix
            ./hosts/dn/hardware.nix
            ./modules/hardened.nix
          ];
        };
      };
    };
}
