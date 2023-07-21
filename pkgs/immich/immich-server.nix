{ lib, buildNpmPackage, fetchFromGitHub, pkg-config
, vips
, python3

}:

buildNpmPackage rec {
  pname = "immich-server";
  inherit (import ./src.nix { inherit fetchFromGitHub; }) version src;

  sourceRoot = "source/server";

  npmDepsHash = "sha256-P++QhrYz2I5tgdFIql7CsDN5X3NFAeUHn9vKtURdzjU=";

  nativeBuildInputs = [
    pkg-config
    python3
  ];

  patches = [./immich-server.patch];

  buildInputs = [
    vips
  ];

}
