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

    modprobed-db = callPackage ./modprobed-db.nix {};
    wpantund = callPackage ./wpantund {};
  };
in
  lib.fix (lib.extends overrides packages)
