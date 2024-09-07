{pkgs ? import <nixpkgs> {}}: let
  callPackage = pkgs.callPackage;
in {
  dcc = callPackage ./dcc {};

  deptree = callPackage ./deptree.nix {};

  fre = callPackage ./fre.nix {};

  git-no-hooks = callPackage ./git-no-hooks {};

  go-mod-upgrade = callPackage ./go-mod-upgrade.nix {};

  goplantuml = callPackage ./goplantuml.nix {};

  immich-go = callPackage ./immich-go.nix {};

  insomnium = callPackage ./insomnium.nix {};

  modprobed-db = callPackage ./modprobed-db.nix {};

  pgvecto-rs = callPackage ./pgvecto-rs.nix {};

  tun2proxy = callPackage ./tun2proxy {};

  wl-gammarelay-rs = callPackage ./wl-gammarelay-rs.nix {};

  zeronsd = callPackage ./zeronsd {};
}
