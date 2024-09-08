{pkgs ? import <nixpkgs> {}}: let
  callPackage = pkgs.callPackage;
in {
  aider-chat = callPackage ./aider.nix {};

  butterfish = callPackage ./butterfish.nix {};

  dcc = callPackage ./dcc {};

  deptree = callPackage ./deptree.nix {};

  fabric-ai = callPackage ./fabric-ai.nix {};

  fre = callPackage ./fre.nix {};

  git-no-hooks = callPackage ./git-no-hooks {};

  go-mod-upgrade = callPackage ./go-mod-upgrade.nix {};

  goplantuml = callPackage ./goplantuml.nix {};

  immich-go = callPackage ./immich-go.nix {};

  insomnium = callPackage ./insomnium.nix {};

  llm-ollama = callPackage ./llm-ollama.nix {};

  magic-cli = callPackage ./magic-cli {};

  modprobed-db = callPackage ./modprobed-db.nix {};

  pgvecto-rs = callPackage ./pgvecto-rs.nix {};

  resticprofile = callPackage ./resticprofile.nix {};

  shh = callPackage ./shh.nix {};

  tun2proxy = callPackage ./tun2proxy {};

  zeronsd = callPackage ./zeronsd {};
}
