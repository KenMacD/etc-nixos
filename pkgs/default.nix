{
  pkgs ? import <nixpkgs> {},
  overrides ? (self: super: {}),
}:
with pkgs; let
  packages = self: let
    callPackage = newScope self;
  in {
    fre = callPackage ./fre {};
    wpantund = callPackage ./wpantund {};
  };
in
  lib.fix (lib.extends overrides packages)
