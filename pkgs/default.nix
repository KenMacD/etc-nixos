{ pkgs ? import <nixpkgs> { }, overrides ? (self: super: { }) }:

with pkgs;

let
  packages = self:
  let callPackage = newScope self;
  in {
    zephyr-toolchain = callPackage ./zephyr-toolchain {};
    };
in lib.fix (lib.extends overrides packages)