{
  pkgs,
  nixpkgs,
}: let
  inherit (pkgs) callPackage python3Packages;
in {
  aider-chat = callPackage ./aider.nix {};

  butterfish = callPackage ./butterfish.nix {};

  dcc = callPackage ./dcc {};

  deptree = callPackage ./deptree.nix {};

  fabric-ai = callPackage ./fabric-ai.nix {};

  files-to-prompt = python3Packages.callPackage ./files-to-prompt.nix {};

  fre = callPackage ./fre.nix {};

  fwdctrl = python3Packages.callPackage ./fwdctrl.nix {};

  git-no-hooks = callPackage ./git-no-hooks {};

  go-mod-upgrade = callPackage ./go-mod-upgrade.nix {};

  goplantuml = callPackage ./goplantuml.nix {};

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
    extraBuildInputs = [pkgs.xz];
  };

  repopack = callPackage ./repopack.nix {};

  pgvecto-rs = callPackage ./pgvecto-rs.nix {};

  resticprofile = callPackage ./resticprofile.nix {};

  shh = callPackage ./shh.nix {};

  tun2proxy = callPackage ./tun2proxy {};

  windsurf = callPackage ./windsurf.nix {inherit nixpkgs;};

  zeronsd = callPackage ./zeronsd {};
}
