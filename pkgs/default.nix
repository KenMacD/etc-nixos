{
  pkgs ? import <nixpkgs> {},
  overrides ? (self: super: {}),
  inputs,
}:
with pkgs; let
  packages = self: let
    callPackage = newScope self;
  in {
    dcc = callPackage ./dcc {};

    fre = callPackage ./fre.nix {};

    immich-go = callPackage ./immich-go.nix {};

    modprobed-db = callPackage ./modprobed-db.nix {};

    pgvecto-rs = callPackage ./pgvecto-rs.nix { fenix = inputs.fenix.packages.${system}; };

    wpantund = callPackage ./wpantund {};
  };
in
  lib.fix (lib.extends overrides packages)
