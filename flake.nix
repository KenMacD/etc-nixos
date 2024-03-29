{
  description = "NixOS configuration";

  nixConfig = {
    extra-experimental-features = ["nix-command" "flakes"];
    max-jobs = "auto";
    auto-optimise-store = "true";
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-staging-next.url = "github:NixOS/nixpkgs/staging-next";
  inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  inputs.nixpkgs-23_05.url = "github:NixOS/nixpkgs/nixos-23.05";
  inputs.nixpkgs-23_11.url = "github:NixOS/nixpkgs/nixos-23.11";
  inputs.nixpkgs-stable.follows = "nixpkgs-23_11";
  inputs.nixpkgs-mongodb-pin.url = "github:NixOS/nixpkgs/106c4ac6aa6e325263b740fd30bdda3b430178ef";
  inputs.nixpkgs-pr291484.url = "github:NixOS/nixpkgs/9c96d0aa255827aa0249148c759a98fc2691db10";

  inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
  };
  inputs.impermanence = {
    url = "github:nix-community/impermanence";
  };
  inputs.microvm = {
    url = "github:astro/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-alien = {
    url = "github:thiagokokada/nix-alien";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-bubblewrap = {
    url = "sourcehut:~fgaz/nix-bubblewrap";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-vscode-extensions = {
    url = "github:nix-community/nix-vscode-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-staging-next,
    nixpkgs-master,
    nixpkgs-stable,
    nixpkgs-mongodb-pin,
    nixpkgs-pr291484,
    devenv,
    fenix,
    flake-utils,
    impermanence,
    microvm,
    nix-alien,
    nix-bubblewrap,
    nix-vscode-extensions,
    sops-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    overlay-local = self: super:
      import ./pkgs {
        pkgs = super;
        inherit inputs;
      };
    overlay-master = final: prev: {
      master = nixpkgs-master.legacyPackages.${prev.system};
    };
    overlay-mongodb-pin = self: super: {
      mongodb-4_4 =
        (import nixpkgs-mongodb-pin {
          inherit system;
          config.allowUnfreePredicate = pkg: "mongodb" == (super.lib.getName pkg);
        })
        .mongodb-4_4;
    };
    overlay-nix-bubblewrap = final: prev: {
      nix-bubblewrap = nix-bubblewrap.packages.${prev.system}.default;
      wrapPackage = nix-bubblewrap.lib.${prev.system}.wrapPackage;
    };
    overlay-stable = final: prev: {
      stable = nixpkgs-stable.legacyPackages.${prev.system};
    };
    overlay-staging-next = final: prev: {
      staging-next = nixpkgs-staging-next.legacyPackages.${prev.system};
    };
    overlay-espanso-new = final: prev: {
      espanso =
        (import nixpkgs-pr291484 {inherit system;})
        .espanso;
    };
  in {
    packages.x86_64-linux = import ./pkgs {
      pkgs = nixpkgs.legacyPackages.${system};
      inherit inputs;
    };

    nixosConfigurations = {
      # nix build .#nixosConfigurations.iso.config.system.build.isoImage
      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./common.nix
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ({
            pkgs,
            lib,
            ...
          }: {
            environment.systemPackages = [pkgs.neovim];

            # Enables copy / paste when running in a KVM with spice.
            services.spice-vdagentd.enable = true;

            # Use faster squashfs compression
            isoImage.squashfsCompression = "gzip -Xcompression-level 1";

            boot.kernelPackages = pkgs.linuxPackages_6_8;
            boot.supportedFilesystems.zfs = lib.mkForce false;
          })
        ];
      };

      r1pro = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({pkgs, ...}: {
            nix.nixPath = let path = toString ./.; in ["repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}"];
            nixpkgs.overlays = [
              overlay-local
            ];
          })
          ./common.nix
          ./hosts/r1pro/configuration.nix
          ./hosts/r1pro/hardware.nix
        ];
      };

      yoga = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({...}: {
            nix.nixPath = let path = toString ./.; in ["repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}"];
            nixpkgs.overlays = [
              overlay-local
              overlay-mongodb-pin
            ];
          })
          ./common.nix
          ./hosts/yoga/configuration.nix
          ./hosts/yoga/hardware.nix
          ./modules/hardened.nix
          ./modules/immich.nix
          sops-nix.nixosModules.sops
        ];
      };
      dn = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system inputs;};
        modules = [
          ({
            config,
            pkgs,
            ...
          }: {
            nixpkgs.overlays = [
              overlay-local
              overlay-staging-next
              overlay-master
              overlay-stable
              # (import ./overlays/sway-dbg.nix)
              overlay-nix-bubblewrap
              (import ./overlays/testing.nix)
              overlay-espanso-new
            ];
          })
          # Add to regsitry so nixpkgs commands use system versions
          ({pkgs, ...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.nixpkgs-master.flake = nixpkgs-master;
            nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
            nix.registry.nixpkgs-mongodb-pin.flake = nixpkgs-mongodb-pin;
            nix.registry.microvm.flake = microvm;
            nix.registry.devenv.flake = devenv;
            nix.registry.local.flake = self;
          })
          ({pkgs, ...}: {
            virtualisation.podman.enable = true;
            virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
            networking.firewall.allowedUDPPorts = [53];
          })
          ({...}: {
            # Use the flakes' nixpkgs for commands
            nix.nixPath = let path = toString ./.; in ["repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}"];
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
      atom = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./common.nix
          ./hosts/atom/configuration.nix
          ./hosts/atom/hardware.nix
          ./modules/hardened.nix
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
