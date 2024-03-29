{
  description = "NixOS configuration";

  nixConfig = {
    extra-experimental-features = ["nix-command" "flakes" "ca-derivations"];
    max-jobs = "auto";
    auto-optimise-store = "true";
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-staging-next.url = "github:NixOS/nixpkgs/staging-next";
  inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  inputs.nixpkgs-23_05.url = "github:NixOS/nixpkgs/nixos-23.05";
  inputs.nixpkgs-stable.follows = "nixpkgs-23_05";
  inputs.nixpkgs-mongodb-pin.url = "github:NixOS/nixpkgs/106c4ac6aa6e325263b740fd30bdda3b430178ef";

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
  inputs.llama-cpp = {
    url = "github:ggerganov/llama.cpp";
    inputs.nixpkgs.follows = "nixpkgs";
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
  # piped test
  inputs.squalus = {
    url = "github:squalus/flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,

    nixpkgs,
    nixpkgs-staging-next,
    nixpkgs-master,
    nixpkgs-stable,
    nixpkgs-mongodb-pin,

    devenv,
    fenix,
    flake-utils,
    #llama-cpp,
    microvm,
    nix-alien,
    nix-bubblewrap,
    nix-vscode-extensions,
    sops-nix,
    squalus,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    overlay-local = self: super: import ./pkgs {pkgs = super; inherit inputs; };
    overlay-staging-next = final: prev: {
      staging-next = nixpkgs-staging-next.legacyPackages.${prev.system};
    };
    overlay-master = final: prev: {
      master = nixpkgs-master.legacyPackages.${prev.system};
    };
    overlay-stable = final: prev: {
      stable = nixpkgs-stable.legacyPackages.${prev.system};
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
  in {
    packages.x86_64-linux =
      import ./pkgs {pkgs = nixpkgs.legacyPackages.${system}; inherit inputs; };

    nixosConfigurations = {
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
              overlay-nix-bubblewrap
              (import ./overlays/testing.nix)
            ];
          })
          # Add to regsitry so nixpkgs commands use system versions
          ({pkgs, ...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.nixpkgs-master.flake = nixpkgs-master;
            nix.registry.nixpkgs-stable.flake = nixpkgs-stable;
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
