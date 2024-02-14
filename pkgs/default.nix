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

    freerdp3 = libsForQt5.callPackage ./freerdp3.nix {
      inherit (darwin.apple_sdk.frameworks) AudioToolbox AVFoundation Carbon Cocoa CoreMedia;
      inherit (gst_all_1) gstreamer gst-plugins-base gst-plugins-good;
    };

    immich-go = callPackage ./immich-go.nix {};

    modprobed-db = callPackage ./modprobed-db.nix {};

    pgvecto-rs = callPackage ./pgvecto-rs.nix {};

    wpantund = callPackage ./wpantund {};
  };
in
  lib.fix (lib.extends overrides packages)
