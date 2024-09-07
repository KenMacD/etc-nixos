{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "shh";
  version = "2024.4.5";

  src = fetchFromGitHub {
    owner = "desbma";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-9ELu4v7/+vhIR8fT00zJ6vCwiz0W8+4n/C/KMo+on6I=";
  };

  cargoHash = "sha256-NtaWjDOYNfYBkoUWHIn477oRrdSqh9DOe/y6RwJewdg=";

  doCheck = false;

  meta = with lib; {
    description = "Automatic systemd service hardening guided by strace profiling";
    homepage = "https://github.com/desbma/shh";
    license = licenses.gpl3;
    maintainers = [];
  };
}
