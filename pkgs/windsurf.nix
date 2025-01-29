{
  lib,
  stdenv,
  nixpkgs,
  callPackage,
  fetchurl,
  nixosTests,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:
# https://windsurf-stable.codeium.com/api/update/linux-x64/stable/latest
let
  version = "1.2.2"; # "windsurfVersion"
  urlHash = "be4251dfb74e60e80fa973d61f3505da1ac9032e"; # "version"
  hash = "sha256-s53azwr+bO7UHVAq0iydP09z7ZK9rvF2P7NKoGPmUMM=";
in
  callPackage "${nixpkgs}/pkgs/applications/editors/vscode/generic.nix" rec {
    inherit commandLineArgs useVSCodeRipgrep version;

    pname = "windsurf";

    executableName = "windsurf";
    longName = "Windsurf";
    shortName = "windsurf";

    src = fetchurl {
      inherit hash;
      url = "https://windsurf-stable.codeiumdata.com/linux-x64/stable/${urlHash}/Windsurf-linux-x64-${version}.tar.gz";
    };

    sourceRoot = "Windsurf";

    tests = nixosTests.vscodium;

    updateScript = "nil";

    meta = {
      description = "The first agentic IDE, and then some";
    };
  }
