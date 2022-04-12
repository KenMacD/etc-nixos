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
      overlay-sway = import ./overlays/sway-dbg;
    in {
      packages.x86_64-linux = import ./pkgs {
        pkgs = nixpkgs.legacyPackages.${system};
      };

      nixosConfigurations = {
        cubie = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./common.nix
            ./modules/avahi-alias.nix
            ./hosts/cubie/configuration.nix
            ./hosts/cubie/hardware.nix
            ./modules/hardened.nix
          ];
        };
        dn = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-local
                overlay-staging-next
                overlay-master
                (import ./overlays/broken-zfs.nix)
                (import ./overlays/sway-dbg.nix)
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
            ./modules/wpantund.nix
            ./hosts/dn/configuration.nix
            ./hosts/dn/hardware.nix
            ./modules/hardened.nix
          ];
        };
      };
    };
}
