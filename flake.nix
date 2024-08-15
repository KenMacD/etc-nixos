{
  description = "NixOS configuration";


  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.nixpkgs-stable.follows = "nixpkgs-24_05";
  inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";

  inputs.nixpkgs-mongodb-pin.url = "github:NixOS/nixpkgs/33be72b31b7cc5a0b43cc3b6c005cf4e4d47d899"; # 2024-06-28

  inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.flake-programs-sqlite = {
    url = "github:wamserma/flake-programs-sqlite";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
  };
  inputs.impermanence = {
    url = "github:nix-community/impermanence";
  };
  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.4.1";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.microvm = {
    url = "github:astro/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.nix-alien = {
    url = "github:thiagokokada/nix-alien";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.nixos-needsreboot = {
    url = "github:thefossguy/nixos-needsreboot";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-bubblewrap = {
    url = "sourcehut:~fgaz/nix-bubblewrap";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.nix-vscode-extensions = {
    url = "github:nix-community/nix-vscode-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-master,
    nixpkgs-mongodb-pin,
    nixpkgs-stable,
    devenv,
    fenix,
    flake-programs-sqlite,
    flake-utils,
    impermanence,
    lanzaboote,
    microvm,
    nix-alien,
    nix-bubblewrap,
    nix-vscode-extensions,
    nixos-needsreboot,
    sops-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    unfreePackages = import ./unfree.nix;

    lib = (import nixpkgs {inherit system;}).lib;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
    };
    overlay-local = self: super:
      import ./pkgs {
        pkgs = super;
        inherit inputs;
      };
    overlay-mongodb-pin = self: super: let
      pinned-pkgs = import nixpkgs-mongodb-pin {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (super.lib.getName pkg) unfreePackages;
      };
    in {
      mongodb-5_0 = pinned-pkgs.mongodb-5_0;
      mongodb-6_0 = pinned-pkgs.mongodb-6_0;
    };
    overlay-nix-bubblewrap = final: prev: {
      nix-bubblewrap = nix-bubblewrap.packages.${prev.system}.default;
      wrapPackage = nix-bubblewrap.lib.${prev.system}.wrapPackage;
    };
    overlay-nix-master = self: super: {
      master = import nixpkgs-master {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (super.lib.getName pkg) unfreePackages;
      };
    };
    overlay-stable = self: super: {
      stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (super.lib.getName pkg) unfreePackages;
      };
    };
  in rec {
    packages.x86_64-linux = import ./pkgs {
      pkgs = nixpkgs.legacyPackages.${system};
      inherit inputs;
    };

    # nix develop local#<shell>
    devShells.${system} = {
      nodejs = pkgs.mkShellNoCC {
        packages = with pkgs; [
          nodejs
          pnpm
          yarn
        ];
      };
      python = pkgs.mkShellNoCC {
        packages = with pkgs; [
          (python3.withPackages (ps:
            with ps; [
              cython
              pip
              pip-tools
              setuptools
              tox
              virtualenv
            ]))
        ];
      };
    };

    nixosConfigurations = {
      # nix build path:/home/kenny/src/nixos#nixosConfigurations.iso.config.system.build.isoImage
      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system inputs;};
        modules = [
          ./common.nix
          sops-nix.nixosModules.sops
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
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

            boot.supportedFilesystems.bcachefs = true;
            boot.supportedFilesystems.zfs = lib.mkForce false;
          })
        ];
      };

      r1pro = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system inputs;};
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
          flake-programs-sqlite.nixosModules.programs-sqlite
          sops-nix.nixosModules.sops
        ];
      };

      yoga = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system inputs;};
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
          flake-programs-sqlite.nixosModules.programs-sqlite
          sops-nix.nixosModules.sops
        ];
      };
      an = nixpkgs.lib.nixosSystem {
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
              overlay-stable
            ];
          })
          # Add to regsitry so nixpkgs commands use system versions
          ({pkgs, ...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
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
          ./modules/nix-alien.nix
          ./hosts/an/configuration.nix
          ./hosts/an/hardware.nix
          ./modules/hardened.nix
          sops-nix.nixosModules.sops
        ];
      };
      ke = nixpkgs.lib.nixosSystem {
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
              overlay-mongodb-pin
              overlay-nix-master
              overlay-stable
              # (import ./overlays/sway-dbg.nix)
              overlay-nix-bubblewrap
              (import ./overlays/testing.nix)
            ];
          })
          # Add to regsitry so nixpkgs commands use system versions
          ({pkgs, ...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
            nix.registry.nixpkgs-master.flake = nixpkgs-master;
            nix.registry.nixpkgs-mongodb-pin.flake = nixpkgs-mongodb-pin;
            nix.registry.devenv.flake = devenv;
            nix.registry.local.flake = self;
            nix.registry.microvm.flake = microvm;
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
          ./modules/nix-alien.nix
          ./hosts/ke/configuration.nix
          ./hosts/ke/hardware.nix
          ./modules/hardened.nix
          flake-programs-sqlite.nixosModules.programs-sqlite
          lanzaboote.nixosModules.lanzaboote
          microvm.nixosModules.host
          sops-nix.nixosModules.sops
          # TODO: script this for all devshells?
          ({...}: {
            system.extraDependencies = [
              devShells.${system}.python
            ];
          })
        ];
      };
    };
  };
}
