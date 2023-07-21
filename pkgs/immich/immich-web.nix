{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "immich-web";
  inherit (import ./src.nix { inherit fetchFromGitHub; }) version src;

  sourceRoot = "source/web";

  npmDepsHash = "sha256-mW7pXWvbZD/qPo2Vz+PcMKDsDZdhj/gW7P6Slz4wiEQ=";

  patches = [./immich-web.patch];
}
