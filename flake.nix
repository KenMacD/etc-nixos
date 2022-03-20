{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.nixpkgs-staging-next.url = "nixpkgs/staging-next";
  inputs.nixpkgs-master.url = "nixpkgs/master";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ self, nixpkgs, nixpkgs-staging-next, nixpkgs-master, flake-utils }:

    let
      system = "x86_64-linux";
      overlay-local = self: super: import ./pkgs { pkgs = super; };
      overlay-staging-next = final: prev: {
        staging-next = nixpkgs-staging-next.legacyPackages.${prev.system};
      };
      overlay-master = final: prev: {
        master = nixpkgs-master.legacyPackages.${prev.system};
      };
    in {
      packages.x86_64-linux = import ./pkgs {
          # TODO: pkgs need overlays?
          pkgs = import nixpkgs { inherit system;  };
      };

      nixosConfigurations = {
        dn = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-staging-next
                overlay-local
                overlay-master
              ];
            })
            # Add to regsitry so nixpkgs commands use system versions
            ({ pkgs, ... }: {
              nix.registry.nixpkgs.flake = inputs.nixpkgs;
              nix.registry.nixpkgs-master.flake = inputs.nixpkgs-master;
              nix.registry.local.flake = self;
            })
            ./common.nix
            ./modules/nrf52.nix
            ./hosts/dn/configuration.nix
            ./hosts/dn/hardware.nix
            ./modules/hardened.nix
          ];
        };
      };
    };
}
