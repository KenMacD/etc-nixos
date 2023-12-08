{
  pkgs ? import <nixpkgs> {},
  overrides ? (self: super: {}),
}:
with pkgs; let
  packages = self: let
    callPackage = newScope self;
  in {
    dcc = callPackage ./dcc {};

    fre = callPackage ./fre {};

    immich-go = callPackage ./immich-go.nix {};

    modprobed-db = callPackage ./modprobed-db.nix {};

    pgvecto-rs = callPackage ./pgvecto-rs.nix {};

    wpantund = callPackage ./wpantund {};
  };
in
  lib.fix (lib.extends overrides packages)
