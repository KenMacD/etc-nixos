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
    inputs.flake-utils.follows = "flake-utils";
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
    nix-bubblewrap,
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
    overlay-old-stable = self: super: {
      old-stable = import nixpkgs-old-stable {
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
    packages.${system} = import ./pkgs {
      inherit nixpkgs;
      pkgs = nixpkgs.legacyPackages.${system};
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
        specialArgs = {inherit system inputs;};
        modules = [
          ./common.nix
          sops-nix.nixosModules.sops
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5-new-kernel.nix"
          ({
            pkgs,
            lib,
            ...
          }: {
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
        specialArgs = {inherit self system inputs;};
        modules = [
          ({...}: {
            nix.nixPath = let path = toString ./.; in ["repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}"];
            nixpkgs.overlays = [
              overlay-nix-master
            ];
          })
          ./common.nix
          ./hosts/r1pro/configuration.nix
          ./hosts/r1pro/hardware.nix
          sops-nix.nixosModules.sops
        ];
      };

      yoga = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit self system inputs;};
        modules = [
          ({...}: {
            nix.nixPath = let path = toString ./.; in ["repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}"];
          })
          ./common.nix
          ./hosts/yoga/configuration.nix
          ./hosts/yoga/hardware.nix
          ./modules/hardened.nix
          ./modules/immich.nix
          sops-nix.nixosModules.sops
        ];
      };
      an = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit system inputs;};
        modules = [
          ({...}: {
            nixpkgs.overlays = [
              overlay-stable
            ];
          })
          # Add to regsitry so nixpkgs commands use system versions
          ({...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
            nix.registry.microvm.flake = microvm;
            nix.registry.devenv.flake = devenv;
            nix.registry.local.flake = self;
          })
          ({...}: {
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
        specialArgs = {inherit self system inputs;};
        modules = [
          ({...}: {
            nixpkgs.overlays = [
              overlay-nix-master
              overlay-old-stable
              overlay-stable
              # (import ./overlays/sway-dbg.nix)
              overlay-nix-bubblewrap

              # Add pkgs.rust-bin packages
              rust-overlay.overlays.default

              (final: prev: {
                glaumar_repo = inputs.glaumar_repo.packages."${prev.system}";
              })

              (import ./overlays/testing.nix)
              (import ./overlays/broken.nix)
            ];
          })
          # Add to regsitry so nixpkgs commands use system versions
          ({...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.nixpkgs-old-stable.flake = nixpkgs-old-stable;
            nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
            nix.registry.nixpkgs-master.flake = nixpkgs-master;
            nix.registry.devenv.flake = devenv;
            nix.registry.local.flake = self;
            nix.registry.microvm.flake = microvm;
          })
          ({...}: {
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
