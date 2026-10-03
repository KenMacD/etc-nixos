{
  pkgs,
  nixpkgs,
  nix-ai-tools,
  nix-ai-tools-3_11,
  system,
}: let
  inherit (pkgs) callPackage python3Packages;
  nodePackages = import ./node2nix/override.nix {
    inherit pkgs;
    nodejs = pkgs.nodejs_24;
  };
in {
  acpx = callPackage ./acpx {};

  alph-cli = callPackage ./alph-cli.nix {};

  butterfish = callPackage ./butterfish.nix {};

  byterover-cli = callPackage ./byterover-cli {};

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

  firefox-devtools-mcp = callPackage ./firefox-devtools-mcp.nix {};

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

  packnplay = callPackage ./packnplay.nix {};

  pi-acp = callPackage ./pi-acp {};

  playwright-mcp = callPackage ./playwright-mcp.nix {};

  pynzbget = python3Packages.callPackage ./pynzbget.nix {};

  qlty = callPackage ./qlty.nix {};

  skeeter-deleter = python3Packages.callPackage ./skeeter-deleter.nix {};

  souffle-addon = callPackage ./souffle-addon {};

  spec-kit = python3Packages.callPackage ./spec-kit.nix {};

  tvly = python3Packages.callPackage ./tvly.nix {};

  vast-cli = let
    # borb 3.0.4 in nixpkgs ships a stale disabledTestPaths glob
    # ("tests/pdf/" no longer exists) that aborts its test phase; skip it.
    borb = python3Packages.borb.overridePythonAttrs (_: {doCheck = false;});
  in
    python3Packages.callPackage ./vast-cli.nix {inherit borb;};

  windmill = callPackage ./windmill {};

  zcode-acp = callPackage ./zcode-acp.nix {
    # zcode-acp v0.3.2 pins ZCode 3.11.2 via an embedded artifact hash that
    # doctor re-verifies at runtime; move this pin up alongside that package.
    zcode = nix-ai-tools-3_11.packages.${system}.zcode;
  };
  ttok = python3Packages.callPackage ./ttok.nix {};
}
