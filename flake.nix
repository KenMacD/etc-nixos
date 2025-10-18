{
  description = "NixOS configuration";

  # https://channels.nixos.org/
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.nixpkgs-25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.nixpkgs-old-stable.follows = "nixpkgs-24_11";
  inputs.nixpkgs-stable.follows = "nixpkgs-25_05";
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
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
  };
  # Include QRookie
  inputs.glaumar_repo = {
    url = "github:glaumar/nur";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.impermanence = {
    url = "github:nix-community/impermanence";
  };
  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.4.2";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.microvm = {
    url = "github:astro/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
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
    inputs.flake-utils.follows = "flake-utils";
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
    lanzaboote,
    microvm,
    nix-ai-tools,
    nix-bubblewrap,
    nixos-needsreboot,
    rust-overlay,
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
    local = self.packages.${system};
    common = {
      imports = [ ./common.nix ];
      nix.registry = lib.mapAttrs (_: flake: {inherit flake;}) (lib.filterAttrs (_: lib.isType "flake") inputs);
      nix.nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") (lib.filterAttrs (_: lib.isType "flake") inputs);
      nixpkgs.overlays = lib.mkBefore [
        (final: prev: {
          nix-ai-tools = nix-ai-tools.packages.${prev.system};
          nix-bubblewrap = nix-bubblewrap.packages.${prev.system}.default;
          nixos-needsreboot = nixos-needsreboot.packages.${prev.system}.default;
          wrapPackage = nix-bubblewrap.lib.${prev.system}.wrapPackage;

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
        rust-overlay.overlays.default
      ];
    };
  in rec {
    packages.${system} =
      (import ./pkgs {
        inherit nixpkgs;
        pkgs = nixpkgs.legacyPackages.${system};
      });

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
      python313 = pkgs.mkShellNoCC {
        packages = with pkgs; [
          (python313.withPackages (ps:
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
      rustup = pkgs.mkShellNoCC {
        packages = with pkgs; [
          rustup
          llvmPackages.bintools
          llvmPackages.clang
          llvmPackages.lld
          pkg-config
          sccache

          # Very commonly needed by crates
          openssl
        ];
        shellHook = ''
          export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
        '';
      };
      rust = pkgs.mkShellNoCC {
        packages = with pkgs; [
          alejandra
          cargo
          cargo-binutils
          cargo-expand
          cargo-flamegraph
          cargo-generate
          clippy
          llvmPackages.bintools
          llvmPackages.clang
          llvmPackages.lld
          pkg-config
          rustc
          rustup
          rust-analyzer
          sccache

          # Very commonly needed by crates
          openssl
        ];
        shellHook = ''
          export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
        '';
      };
      solana = pkgs.mkShellNoCC {
        packages = with pkgs; [
          anchor
          solana-cli
        ];
        shellHook = ''
          export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
        '';
      };
      haskell = pkgs.mkShell {
        # https://haskell4nix.readthedocs.io/nixpkgs-users-guide.html#how-to-create-a-development-environment
        packages = with pkgs; [
          haskellPackages.ghc
          haskellPackages.cabal-install
          haskellPackages.haskell-language-server
        ];
      };
      ether = pkgs.mkShell {
        shellHook = ''
          export SOUFFLE_ADDON="${local.souffle-addon}/lib/"
          export Z3_LIBRARY_PATH="${pkgs.z3.lib}/lib"
        '';
        packages = let
          crytic-compile = crytic.lib.${system}.mkCryticCompile {
            commitHash = "7ce1189e7a052c20f77727e55a3d879d078c5829";
            version = "0.3.8";
          };
          slither-compile = crytic.lib.${system}.mkSlither {
            commitHash = "a77738fe04571a6639ebf82b8c96536ddfcf29b1";
            version = "0.11.0";
            crytic-compile = crytic-compile;
          };
          medusa-compile = crytic.lib.${system}.mkMedusa {
            crytic-compile = crytic-compile;
            slither = slither-compile;
          };
        in
          with pkgs; [
            nodejs
            pnpm
            yarn

            # If want to use nightly, look at foundry input and use foundry.defaultPackage.${system}
            foundry

            # Decompilers
            # In Python Packages: pyevmasm
            evmdis
            local.heimdall-rs
            local.souffle-addon
            souffle

            crytic.packages.${system}.solc-select
            crytic-compile
            slither-compile
            medusa-compile
            crytic.packages.${system}.echidna
            #(crytic.lib.${system}.mkVscode {
            #  extensions = with pkgs.vscode-extensions; [
            #    vscodevim.vim # Add more vscode extensions like so
            #  ];
            #})

            # source packages
            (pkgs.writeShellScriptBin "halmos" "/home/kenny/src/crypto/halmos/venv/bin/halmos $@")

            # SMT Solvers
            bitwuzla
            cvc5
            yices
            z3
          ];
      };
    };

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
            system.stateVersion = "25.11";  # Force version to match installer
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
#          ./modules/nix-alien.nix
          ./hosts/an/configuration.nix
          ./hosts/an/hardware.nix
          ./modules/hardened.nix
          sops-nix.nixosModules.sops
        ];
      };
      ke = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit self system;};
        modules = [
          common
          ({...}: {
            nixpkgs.overlays = [
              # (import ./overlays/sway-dbg.nix)
              (final: prev: {
                glaumar_repo = inputs.glaumar_repo.packages."${prev.system}";
              })

              (import ./overlays/testing.nix)
              (import ./overlays/broken.nix)
            ];
          })
          ({...}: {
            virtualisation.podman.enable = true;
            virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
            networking.firewall.allowedUDPPorts = [53];
          })
#          ./modules/nix-alien.nix
          ./hosts/ke/configuration.nix
          ./hosts/ke/hardware.nix
          ./modules/hardened.nix

          disko.nixosModules.disko
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
