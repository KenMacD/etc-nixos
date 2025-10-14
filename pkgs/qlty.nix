{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  protobuf,
  bzip2,
  libgit2,
  oniguruma,
  openssl,
  xz,
  zlib,
  zstd,
  stdenv,
  darwin,
  git,
}:
# Modified from: https://github.com/ourgal/snowfall/blob/main/packages/qlty/default.nix
let
  version = "0.581.0";
  src = fetchFromGitHub {
    owner = "qltysh";
    repo = "qlty";
    rev = "v${version}";
    fetchSubmodules = false;
    sha256 = "sha256-6gAEthjlHs2gF1plxSiUA249qZyrR/p9jOGegOv32Rg=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "qlty";
    inherit src version;
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "duct-0.13.7" = "sha256-Txzn025lWXctujpAnmp6JLyWLw7rhloCV5tCa+KkAlA=";
      };
    };

    nativeBuildInputs = [
      pkg-config
      protobuf
      git
    ];

    buildInputs =
      [
        bzip2
        libgit2
        oniguruma
        openssl
        xz
        zlib
        zstd
      ]
      ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.CoreFoundation
        darwin.apple_sdk.frameworks.CoreServices
        darwin.apple_sdk.frameworks.IOKit
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];

    env = {
      OPENSSL_NO_VENDOR = true;
      RUSTONIG_SYSTEM_LIBONIG = true;
      ZSTD_SYS_USE_PKG_CONFIG = true;
    };

    doCheck = false;

    meta = {
      description = "Qlty CLI: Universal linting, formatting, maintainability, security scanning, and metrics";
      homepage = "https://github.com/qltysh/qlty";
      changelog = "https://github.com/qltysh/qlty/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.bsl11;
      maintainers = [];
      mainProgram = "qlty";
    };
  }
