{
  pkgs,
  nixpkgs,
}: let
  inherit (pkgs) callPackage python3Packages;
in {
  butterfish = callPackage ./butterfish.nix {};

  dcc = callPackage ./dcc {};

  deptree = callPackage ./deptree.nix {};

  fwdctrl = python3Packages.callPackage ./fwdctrl.nix {};

  git-no-hooks = callPackage ./git-no-hooks {};

  goplantuml = callPackage ./goplantuml.nix {};

  heimdall-rs = callPackage ./heimdall-rs.nix {};

  llm-deepseek = python3Packages.callPackage ./llm-deepseek.nix {};

  llm-groq = python3Packages.callPackage ./llm-groq.nix {};

  magic-cli = callPackage ./magic-cli {};

  mongodb-bin_7 = callPackage ./mongodb-bin.nix {
    version = "7.0.14";
    hash = "sha256-tM+MquEIeFE17Mi4atjtbfXW77hLm5WlDsui/CRs4IQ=";
  };
  mongodb-bin_6 = callPackage ./mongodb-bin.nix {
    version = "6.0.17";
    hash = "sha256-zZ1ObTLo15UNxCjck56LWMrf7FwRapYKCwfU+LeUmi0=";
    extraBuildInputs = [pkgs.xz];
  };

  ofc = callPackage ./ofc.nix {};

  pgvecto-rs = callPackage ./pgvecto-rs.nix {};

  playwright-mcp = callPackage ./playwright-mcp.nix {};

  souffle-addon = callPackage ./souffle-addon {};

  ttok = python3Packages.callPackage ./ttok.nix {};
}
