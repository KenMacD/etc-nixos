{
  pkgs,
  nixpkgs,
}: let
  inherit (pkgs) callPackage python3Packages;
  nodePackages = import ./node2nix/override.nix {
    inherit pkgs;
    nodejs = pkgs.nodejs_24;
  };
in {
  alph-cli = callPackage ./alph-cli.nix {};

  butterfish = callPackage ./butterfish.nix {};

  cctx = callPackage ./cctx.nix {};

  cclimits = callPackage ./cclimits.nix {};

  chrome-devtools-mcp = callPackage ./chrome-devtools-mcp.nix {};

  code-assistant-manager = python3Packages.callPackage ./code-assistant-manager {};

  container-use = callPackage ./container-use.nix {};

  dbhub = callPackage ./dbhub.nix {};

  dcc = callPackage ./dcc {};

  depsguard = callPackage ./depsguard.nix {};

  deptree = callPackage ./deptree.nix {};

  ferretdb2 = callPackage ./ferretdb2.nix {};

  fwdctrl = python3Packages.callPackage ./fwdctrl.nix {};

  git-no-hooks = callPackage ./git-no-hooks {};

  goplantuml = callPackage ./goplantuml.nix {};

  heimdall-rs = callPackage ./heimdall-rs.nix {};

  magic-cli = callPackage ./magic-cli {};

  mcp2cli = python3Packages.callPackage ./mcp2cli.nix {};

  mcp-server-tree-sitter = callPackage ./mcp-server-tree-sitter.nix {};

  mcptools = callPackage ./mcptools.nix {};

  mongodb-bin_7 = callPackage ./mongodb-bin.nix {
    version = "7.0.31";
    hash = "sha256-Pana81oKScUG4OXW9qgEV4fJz58nrUQRI+grbRfv/3s=";
  };

  namespaced-openvpn = callPackage ./namespaced-openvpn.nix {};

  octofriend = callPackage ./octofriend.nix {};

  pgvecto-rs = callPackage ./pgvecto-rs.nix {};

  playwright-mcp = callPackage ./playwright-mcp.nix {};

  pynzbget = python3Packages.callPackage ./pynzbget.nix {};

  qlty = callPackage ./qlty.nix {};

  skeeter-deleter = python3Packages.callPackage ./skeeter-deleter.nix {};

  souffle-addon = callPackage ./souffle-addon {};

  spec-kit = python3Packages.callPackage ./spec-kit.nix {};

  tvly = python3Packages.callPackage ./tvly.nix {};

  windmill = callPackage ./windmill {};

  ttok = python3Packages.callPackage ./ttok.nix {};
}
