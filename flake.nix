{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/nixos-unstable.tar.gz";
  inputs.nixpkgs-staging-next.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/staging-next.tar.gz";
  inputs.nixpkgs-master.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/master.tar.gz";
  inputs.nixpkgs-22_05.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/nixos-22.05.tar.gz";
  inputs.nixpkgs-stable.follows = "nixpkgs-22_05";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.sops-nix.url = github:Mic92/sops-nix;
  inputs.nix-alien.url = "github:thiagokokada/nix-alien";
  inputs.nix-bubblewrap.url = "sourcehut:~fgaz/nix-bubblewrap";
  inputs.microvm.url = "github:astro/microvm.nix";

  outputs =
    { self
    , nixpkgs
    , nixpkgs-staging-next
    , nixpkgs-master
    , nixpkgs-stable
    , flake-utils
    , sops-nix
    , nix-alien
    , nix-bubblewrap
    , microvm
    , ...
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
      overlay-nix-bubblewrap = final: prev: {
        nix-bubblewrap = nix-bubblewrap.packages.${prev.system}.default;
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
                overlay-nix-bubblewrap
                (final: prev: {
                  kubernetes = (prev.kubernetes.override {
                    buildGoModule = prev.buildGo118Module;
                  }).overrideAttrs (oldAttrs: rec {
                    version = "1.24.3";
                    src = prev.fetchFromGitHub {
                      owner = "kubernetes";
                      repo = "kubernetes";
                      rev = "v${version}";
                      sha256 = "sha256-O/wZv8plaUKLJXVBKCms8joeoY/Abje5mZ1+wBKOQG8=";
                    };
                  });
                })
              ];
            })
            # Add to regsitry so nixpkgs commands use system versions
            ({ pkgs, ... }: {
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.registry.nixpkgs-master.flake = nixpkgs-master;
              nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
              nix.registry.local.flake = self;
            })
            ({ ... }: {
              # Use the flakes' nixpkgs for commands
              nix.nixPath = let path = toString ./.; in [ "repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}" ];
            })
            ./common.nix
            ./modules/wpantund.nix
            ./modules/nix-alien.nix
            ./hosts/dn/configuration.nix
            ./hosts/dn/hardware.nix
            ./modules/hardened.nix
            microvm.nixosModules.host
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
