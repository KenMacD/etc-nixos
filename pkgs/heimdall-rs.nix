{
  darwin,
  fetchFromGitHub,
  lib,
  nix-update-script,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
}:
# From https://github.com/nix-community/ethereum.nix/blob/13a4fbb48aa10a2269a74820b6d835c3cd23c976/pkgs/by-name/he/heimdall/default.nix#L19
rustPlatform.buildRustPackage rec {
  pname = "heimdall";
  version = "0.8.7";

  src = fetchFromGitHub {
    owner = "jon-becker";
    repo = "${pname}-rs";
    rev = version;
    hash = "sha256-Bg3xSnzghLlDpQ1KTzabEVqjX/wPqoeEzKDYb7IBJ6o=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    [
      openssl
    ]
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
      Security
      SystemConfiguration
    ]);

  # Loads of tests do some kind of I/O incompatible with nix sandbox, but are
  # tested in upstream CI.
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "A toolkit for EVM bytecode analysis";
    homepage = "https://heimdall.rs";
    license = [licenses.mit];
    mainProgram = "heimdall";
    platforms = platforms.unix;
  };
}
