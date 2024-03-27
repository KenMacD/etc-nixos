{
  lib,
  rustPlatform,
  fetchFromGitHub,
  openssl,
  pkg-config,
  rustfmt,
}:
rustPlatform.buildRustPackage rec {
  pname = "zeronsd";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "zerotier";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-TL0bgzQgge6j1SpZCdxv/s4pBMSg4/3U5QisjkVE6BE=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [pkg-config];
  buildInputs = [openssl];

  # invalid log level: invalid format
  doCheck = false;

  PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig";
  RUSTFMT = "${rustfmt}/bin/rustfmt";

  meta = with lib; {
    description = "A DNS server for ZeroTier users";
    homepage = "https://www.zerotier.com";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
