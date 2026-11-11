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

  bailian-cli-bin = callPackage ./bailian-cli-bin.nix {};

  # Source-built sibling of bailian-cli-bin; not installed on any host.
  bailian-cli = callPackage ./bailian-cli.nix {};

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

  fwdctrl = python3Packages.callPackage ./fwdctrl.nix {};

  git-no-hooks = callPackage ./git-no-hooks {};

  grev = callPackage ./grev.nix {};

  heimdall-rs = callPackage ./heimdall-rs.nix {};

  hty = callPackage ./hty {};

  kibernetyk-mono = callPackage ./kibernetyk-mono.nix {};

  magic-cli = callPackage ./magic-cli {};

  mcp2cli = python3Packages.callPackage ./mcp2cli.nix {};

  mcp-server-tree-sitter = callPackage ./mcp-server-tree-sitter.nix {};

  mcptools = callPackage ./mcptools.nix {};

  mongodb-bin_7 = callPackage ./mongodb-bin.nix {
    version = "7.0.45";
    hash = "sha256-wu7B5Krulng4QwrFf8fUbCL1ZscY7aYDPjKt2A1Qb4s=";
  };

  namespaced-openvpn = callPackage ./namespaced-openvpn.nix {};

  octofriend = callPackage ./octofriend.nix {};

  packnplay = callPackage ./packnplay.nix {};

  pynzbget = python3Packages.callPackage ./pynzbget.nix {};

  qlty = callPackage ./qlty.nix {};

  skeeter-deleter = python3Packages.callPackage ./skeeter-deleter.nix {};

  souffle-addon = callPackage ./souffle-addon {};

  tvly = python3Packages.callPackage ./tvly.nix {};

  vast-cli = let
    # borb 3.0.4 in nixpkgs ships a stale disabledTestPaths glob
    # ("tests/pdf/" no longer exists) that aborts its test phase; skip it.
    borb = python3Packages.borb.overridePythonAttrs (_: {doCheck = false;});
  in
    python3Packages.callPackage ./vast-cli.nix {inherit borb;};

  zcode-acp = callPackage ./zcode-acp.nix {
    # zcode-acp v0.3.2 pins ZCode 3.11.2 via an embedded artifact hash that
    # doctor re-verifies at runtime; move this pin up alongside that package.
    zcode = nix-ai-tools-3_11.packages.${system}.zcode;
  };
  ttok = python3Packages.callPackage ./ttok.nix {};
}
