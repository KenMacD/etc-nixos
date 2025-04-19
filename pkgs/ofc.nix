{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "ofc";
  version = "e53917abe49d9f88736ef7acabeed573bdc98797";

  src = fetchFromGitHub {
    owner = "elijah-potter";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-kQl5y/QCjQuyA+I8Ip+z3gHs4DawJUcQJPQaa7yqzRA=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-nlPabBIzajRrsyt3Y6cyIKTSf7iWhDS8CJ5DtG6JC2M=";

  nativeBuildInputs = [pkg-config];

  buildInputs = [openssl];

  meta = with lib; {
    description = "A command-line Ollama client for scripting.";
    homepage = "https://github.com/elijah-potter/ofc";
    license = licenses.mit;
    maintainers = [];
  };
}
