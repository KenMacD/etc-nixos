{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/nixos-unstable.tar.gz";
  inputs.nixpkgs-staging-next.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/staging-next.tar.gz";
  inputs.nixpkgs-master.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/master.tar.gz";
  inputs.nixpkgs-22_11.url = "https://git.home.macdermid.ca/mirror/nixpkgs/archive/nixos-22.11.tar.gz";
  inputs.nixpkgs-stable.follows = "nixpkgs-22_11";

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
        yoga = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ ... }: {
              nix.nixPath = let path = toString ./.; in [ "repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}" ];
            })
            ./common.nix
            ./hosts/yoga/configuration.nix
            ./hosts/yoga/hardware.nix
            ./modules/hardened.nix
          ];
        };
        dn = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-local
                overlay-staging-next
                overlay-master
                overlay-stable
                overlay-nix-bubblewrap
                (import ./overlays/testing.nix)
              ];
            })
            # Add to regsitry so nixpkgs commands use system versions
            ({ pkgs, ... }: {
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.registry.nixpkgs-master.flake = nixpkgs-master;
              nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
              nix.registry.microvm.flake = microvm;
              nix.registry.local.flake = self;
            })
            ({ pkgs, ... }: {
              virtualisation.podman.enable = true;
              virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
              networking.firewall.allowedUDPPorts = [ 53 ];
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
