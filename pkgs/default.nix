{
  pkgs,
  nixpkgs,
}: let
  inherit (pkgs) callPackage python3Packages;
  nodePackages = import ./node2nix/override.nix {
    inherit pkgs;
    nodejs = pkgs.nodejs_24;
  };
in
  nodePackages
  // {
    butterfish = callPackage ./butterfish.nix {};

    claude-code-router = callPackage ./claude-code-router.nix {};

    container-use = callPackage ./container-use.nix {};

    dcc = callPackage ./dcc {};

    deptree = callPackage ./deptree.nix {};

    ferretdb2 = callPackage ./ferretdb2.nix {};

    fwdctrl = python3Packages.callPackage ./fwdctrl.nix {};

    git-no-hooks = callPackage ./git-no-hooks {};

    goplantuml = callPackage ./goplantuml.nix {};

    heimdall-rs = callPackage ./heimdall-rs.nix {};

    magic-cli = callPackage ./magic-cli {};

    mcp-inspector = callPackage ./mcp-inspector.nix {};

    mcptools = callPackage ./mcptools.nix {};

    mongodb-bin_7 = callPackage ./mongodb-bin.nix {
      version = "7.0.14";
      hash = "sha256-tM+MquEIeFE17Mi4atjtbfXW77hLm5WlDsui/CRs4IQ=";
    };
    mongodb-bin_6 = callPackage ./mongodb-bin.nix {
      version = "6.0.17";
      hash = "sha256-zZ1ObTLo15UNxCjck56LWMrf7FwRapYKCwfU+LeUmi0=";
      extraBuildInputs = [pkgs.xz];
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

    ttok = python3Packages.callPackage ./ttok.nix {};
  }
