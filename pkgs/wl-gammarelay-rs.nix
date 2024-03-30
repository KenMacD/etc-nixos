{ lib
, fetchFromGitHub
, rustPlatform
}:

# Sources:
# * https://github.com/nix-community/nixpkgs-wayland/blob/master/pkgs/wl-gammarelay-rs/default.nix

rustPlatform.buildRustPackage rec {
  pname = "wl-gammarelay-rs";
  version = "v0.3.2";

  src = fetchFromGitHub {
    owner = "MaxVerevkin";
    repo = "wl-gammarelay-rs";
    rev = "v0.3.2";
    sha256 = "sha256-md6e9nRCs6TZarwFD3/GQEoJSIhtdq++rIZTP7Vl0wQ=";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  meta = with lib; {
    description = "A simple program that provides DBus interface to control display temperature and brightness under wayland without flickering ";
    homepage = "https://github.com/MaxVerevkin/wl-gammarelay-rs";
    license = licenses.gpl3;
  };
}
