{
  lib,
  rustPlatform,
  fetchFromGitHub,
  libxcb,
  openssl,
  pkg-config,
  python3,
}:
rustPlatform.buildRustPackage rec {
  pname = "magic-cli";
  version = "0.0.6";

  checkFlags = [
    "--skip=core::suggestion::tests::test_simple_suggestion"
  ];

  src = fetchFromGitHub {
    owner = "guywaldman";
    repo = pname;
    rev = version;
    sha256 = "sha256-FnLPqEFNUYzWRXokGcis9U4qd06o750riB7CavqO/Vs=";
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  cargoLock.lockFile = ./Cargo.lock;

  buildInputs = [
    libxcb
    openssl
    python3
  ];

  nativeBuildInputs = [
    pkg-config
    python3
  ];

  meta = with lib; {
    description = "Command line utility to make you a magician in the terminal ";
    homepage = "https://guywaldman.com/posts/introducing-magic-cli";
    license = licenses.mit;
    maintainers = with maintainers; [];
  };
}
