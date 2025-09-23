{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  hatchling,
  typer,
  rich,
  httpx,
  platformdirs,
  readchar,
  truststore,
}:
# Modified from: https://github.com/BCNelson/nix-config/blob/287d7930ca8a71b1c7c9be5f834d540ded39e591/pkgs/spec-kit.nix
let
  version = "0.0.52";
in
  buildPythonApplication {
    pname = "spec-kit";
    inherit version;

    src = fetchFromGitHub {
      owner = "github";
      repo = "spec-kit";
      rev = "v${version}";
      sha256 = "sha256-Z940x+CuJWTYFrvaCvdOazRstfLFUhcCnipiE3dlvR4=";
    };

    format = "pyproject";

    nativeBuildInputs = [
      hatchling
    ];

    propagatedBuildInputs = [
      httpx
      platformdirs
      readchar
      rich
      truststore
      typer
    ];

    pythonImportsCheck = ["specify_cli"];

    # - truststore>=0.10.4 not satisfied by version 0.10.1
    # Remove once https://github.com/NixOS/nixpkgs/pull/435001
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "A toolkit to help developers get started with Spec-Driven Development";
      homepage = "https://github.com/github/spec-kit";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "specify";
    };
  }
