{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.nixpkgs-staging-next.url = "nixpkgs/staging-next";
  inputs.nixpkgs-master.url = "nixpkgs/master";
  inputs.nixpkgs-stable.url = "nixpkgs/nixos-21.11";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.sops-nix.url = github:Mic92/sops-nix;

  inputs.nix-alien = {
    url = "github:thiagokokada/nix-alien";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-staging-next
    , nixpkgs-master
    , nixpkgs-stable
    , flake-utils
    , sops-nix
    , nix-alien
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
          specialArgs = inputs;
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-local
                overlay-staging-next
                overlay-master
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
            ./modules/wpantund.nix
            ./modules/nix-alien.nix
            ./hosts/dn/configuration.nix
            ./hosts/dn/hardware.nix
            ./modules/hardened.nix
            sops-nix.nixosModules.sops
          ];
        };
        x1 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./common.nix
            ./hosts/x1/configuration.nix
            ./hosts/x1/hardware.nix
            ./modules/hardened.nix
          ];
        };

      };
    };
}
