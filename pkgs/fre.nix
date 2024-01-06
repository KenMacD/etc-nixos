{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "fre";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "camdencheek";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-cYqEPohqUmewvBUoGJQfa4ATxw2uny5+nUKtNzrxK38=";
  };

  cargoSha256 = "sha256-BEIrjHsIrNkFEEjCrTKwsJL9hptmVOI8x3ZWoo9ZUvQ=";

  meta = with lib; {
    description = "Command line frecency tracking";
    homepage = "https://github.com/camdencheek/fre/";
    license = licenses.mit;
    maintainers = [];
  };
}
