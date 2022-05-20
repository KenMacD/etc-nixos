{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.nixpkgs-staging-next.url = "nixpkgs/staging-next";
  inputs.nixpkgs-master.url = "nixpkgs/master";
  inputs.nixpkgs-stable.url = "nixpkgs/nixos-21.11";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { self
    , nixpkgs
    , nixpkgs-staging-next
    , nixpkgs-master
    , nixpkgs-stable
    , flake-utils
    }@inputs:

    let
      system = "x86_64-linux";
      overlay-local = self: super: import ./pkgs { pkgs = super; };
      overlay-staging-next = final: prev: {
        staging-next = nixpkgs-staging-next.legacyPackages.${prev.system};
      };
      overlay-master = final: prev: {
        master = nixpkgs-master.legacyPackages.${prev.system};
      };
      overlay-stable = final: prev: {
        stable = nixpkgs-stable.legacyPackages.${prev.system};
      };
    in
    {
      packages.x86_64-linux =
        import ./pkgs { pkgs = nixpkgs.legacyPackages.${system}; };

      nixosConfigurations = {
        cubie = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./common.nix
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
                overlay-stable
                (import ./overlays/sway-dbg.nix)
              ];
            })
            # Add to regsitry so nixpkgs commands use system versions
            ({ pkgs, ... }: {
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.registry.nixpkgs-master.flake = nixpkgs-master;
              nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
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
