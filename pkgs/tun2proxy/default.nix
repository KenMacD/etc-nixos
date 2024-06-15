{
  lib,
  coreutils,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "tun2proxy";
  version = "0.2.18";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-3Ircbo4NEk3UBFfqfSd3NUq9LI9Ll4x2MVskUbkQQjQ=";
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  cargoLock = {
    lockFile = ./Cargo.lock;
  };
}
