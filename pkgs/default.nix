{pkgs ? import <nixpkgs> {}}: let
  inherit (pkgs) callPackage python3Packages;
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

  llm-claude-3 = python3Packages.callPackage ./llm-claude-3.nix {};
  llm-ollama = python3Packages.callPackage ./llm-ollama.nix {};

  magic-cli = callPackage ./magic-cli {};

  modprobed-db = callPackage ./modprobed-db.nix {};

  mongodb-bin_7 = callPackage ./mongodb-bin.nix {
    version = "7.0.14";
    hash = "sha256-tM+MquEIeFE17Mi4atjtbfXW77hLm5WlDsui/CRs4IQ=";
  };
  mongodb-bin_6 = callPackage ./mongodb-bin.nix {
    version = "6.0.17";
    hash = "sha256-zZ1ObTLo15UNxCjck56LWMrf7FwRapYKCwfU+LeUmi0=";
    extraBuildInputs = [pkgs.lzma];
  };

  pgvecto-rs = callPackage ./pgvecto-rs.nix {};

  resticprofile = callPackage ./resticprofile.nix {};

  shh = callPackage ./shh.nix {};

  tun2proxy = callPackage ./tun2proxy {};

  zeronsd = callPackage ./zeronsd {};
}
