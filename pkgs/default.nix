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

    deptree = callPackage ./deptree.nix {};

    espanso-wayland = callPackage ./espanso {
      waylandSupport = true;
      x11Support = false;
    };

    fre = callPackage ./fre.nix {};

    freerdp3 = libsForQt5.callPackage ./freerdp3.nix {
      inherit (darwin.apple_sdk.frameworks) AudioToolbox AVFoundation Carbon Cocoa CoreMedia;
      inherit (gst_all_1) gstreamer gst-plugins-base gst-plugins-good;
    };

    git-no-hooks = callPackage ./git-no-hooks {};

    go-mod-upgrade = callPackage ./go-mod-upgrade.nix {};

    goplantuml = callPackage ./goplantuml.nix {};

    immich-go = callPackage ./immich-go.nix {};

    insomnium = callPackage ./insomnium.nix {};

    modprobed-db = callPackage ./modprobed-db.nix {};

    pgvecto-rs = callPackage ./pgvecto-rs.nix {};

    tun2proxy = callPackage ./tun2proxy {};

    wl-gammarelay-rs = callPackage ./wl-gammarelay-rs.nix {};
    wpantund = callPackage ./wpantund {};
    zeronsd = callPackage ./zeronsd {};
  };
in
  lib.fix (lib.extends overrides packages)
