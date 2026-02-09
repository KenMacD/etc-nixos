{
  description = "NixOS configuration";

  # https://channels.nixos.org/
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.nixpkgs-25_11.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.nixpkgs-old-stable.follows = "nixpkgs-25_05";
  inputs.nixpkgs-stable.follows = "nixpkgs-25_11";
  inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";

  inputs.crytic = {
    url = "github:crytic/crytic.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.disko = {
    url = "github:nix-community/disko/latest";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # Include QRookie
  inputs.glaumar_repo = {
    url = "github:glaumar/nur";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.impermanence = {
    url = "github:nix-community/impermanence";
  };
  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.4.2";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.rust-overlay.follows = "rust-overlay"; # https://github.com/nix-community/lanzaboote/issues/485
  };
  inputs.microvm = {
    url = "github:astro/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-ai-tools = {
    url = "github:numtide/nix-ai-tools";
  };
  inputs.nix-alien = {
    url = "github:thiagokokada/nix-alien";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixos-needsreboot = {
    url = "github:thefossguy/nixos-needsreboot";
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
  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-master,
    nixpkgs-old-stable,
    nixpkgs-stable,
    crytic,
    devenv,
    disko,
    home-manager,
    lanzaboote,
    microvm,
    nix-ai-tools,
    nix-alien,
    nix-bubblewrap,
    nix-vscode-extensions,
    nixos-needsreboot,
    rust-overlay,
    sops-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    unfreePackages = import ./unfree.nix;

    lib = import ./lib {
      lib = inputs.nixpkgs.lib;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
    };
    local = self.packages.${system};
    common = {
      imports = [./common.nix];
      nix.registry = lib.mapAttrs (_: flake: {inherit flake;}) (lib.filterAttrs (_: lib.isType "flake") inputs);
      nix.nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") (lib.filterAttrs (_: lib.isType "flake") inputs);
      nixpkgs.overlays = lib.mkBefore [
        (final: prev: {
          nix-ai-tools = nix-ai-tools.packages.${prev.stdenv.hostPlatform.system};
          nix-bubblewrap = nix-bubblewrap.packages.${prev.stdenv.hostPlatform.system}.default;
          nixos-needsreboot = nixos-needsreboot.packages.${prev.stdenv.hostPlatform.system}.default;
          wrapPackage = nix-bubblewrap.lib.${prev.stdenv.hostPlatform.system}.wrapPackage;

          master = import nixpkgs-master {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (prev.lib.getName pkg) unfreePackages;
          };
          old-stable = import nixpkgs-old-stable {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (prev.lib.getName pkg) unfreePackages;
          };
          stable = import nixpkgs-stable {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (prev.lib.getName pkg) unfreePackages;
          };
        })
        nix-alien.overlays.default
        rust-overlay.overlays.default
      ];
    };
  in rec {
    packages.${system} = import ./pkgs {
      inherit nixpkgs;
      pkgs = nixpkgs.legacyPackages.${system};
    };

    # Dynamic devShells from shells/ directory
    # dynamicDevShells = import ./shells {inherit lib pkgs;};
    devShells.${system} = import ./shells {inherit lib pkgs;};

    nixosConfigurations = {
      # nix build path:/home/kenny/src/nixos#nixosConfigurations.iso.config.system.build.isoImage
      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system;};
        modules = [
          common
          sops-nix.nixosModules.sops
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ({
            pkgs,
            lib,
            ...
          }: {
            system.stateVersion = "25.11"; # Force version to match installer
            environment.systemPackages = with pkgs; [
              inputs.disko.packages.${system}.disko
              neovim
              restic
            ];

            # Enables copy / paste when running in a KVM with spice.
            services.spice-vdagentd.enable = true;

            # Use faster squashfs compression
            isoImage.squashfsCompression = "gzip -Xcompression-level 1";

            # Files to include
            isoImage.contents = [
              {
                source = self;
                target = "/nixos/";
              }
            ];

            boot.supportedFilesystems.bcachefs = true;
            boot.supportedFilesystems.zfs = lib.mkForce false;
          })
        ];
      };

      r1pro = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit self system;};
        modules = [
          common
          ./hosts/r1pro/configuration.nix
          ./hosts/r1pro/hardware.nix
          sops-nix.nixosModules.sops
        ];
      };

      yoga = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit self system;};
        modules = [
          common
          ./hosts/yoga/configuration.nix
          ./hosts/yoga/hardware.nix
          ./modules/hardened.nix
          ./modules/immich.nix
          sops-nix.nixosModules.sops
        ];
      };
      an = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system;};
        modules = [
          common
          ({...}: {
            virtualisation.podman.enable = true;
            virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
            networking.firewall.allowedUDPPorts = [53];
          })
          ./modules/nix-alien.nix
          ./hosts/an/configuration.nix
          ./hosts/an/hardware.nix
          ./modules/hardened.nix
          sops-nix.nixosModules.sops
        ];
      };
      ke = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit lib self system;};
        modules = [
          common
          ({...}: {
            nixpkgs.overlays = [
              # (import ./overlays/sway-dbg.nix)
              (final: prev: {
                glaumar_repo = inputs.glaumar_repo.packages."${prev.system}";
              })

              nix-vscode-extensions.overlays.default
              (import ./overlays/testing.nix)
              (import ./overlays/broken.nix)
            ];
          })
          ({...}: {
            virtualisation.podman.enable = true;
            virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
            networking.firewall.allowedUDPPorts = [53];
          })
          ./modules/nix-alien.nix
          ./hosts/ke/configuration.nix
          ./hosts/ke/hardware.nix
          ./modules/hardened.nix

          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          microvm.nixosModules.host
          sops-nix.nixosModules.sops

          # Home Manager configuration:
          home-manager.nixosModules.home-manager
          ({...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.kenny = ./home-manager/users/kenny.nix;
            # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
          })

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
