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
  version = "0.667.0";
  src = fetchFromGitHub {
    owner = "qltysh";
    repo = "qlty";
    rev = "v${version}";
    fetchSubmodules = false;
    sha256 = "sha256-gFBwqVmHWZehbzd6RAWromp8TaiCWB6TSzxNNp3t7Qw=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "qlty";
    inherit src version;
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "duct-0.13.7" = "sha256-Txzn025lWXctujpAnmp6JLyWLw7rhloCV5tCa+KkAlA=";
        "lithos-llm-0.1.0" = "sha256-g1x2u4OWxTUUloYJTIuxARVRMVz1C8OKrjLmcB3XyE0=";
        "tree-sitter-javascript-0.21.4" = "sha256-28KDB4NFglmtMuqh2T8aTZ7w+UYfauMGsjpQP1gDWxI=";
        "tree-sitter-vb-dotnet-0.1.0" = "sha256-6qv0D3lf+madJ0mXfNj6Bd8ce7aacSQBxALBNzTSRuA=";
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
      # license = lib.licenses.bsl11;
      maintainers = [];
      mainProgram = "qlty";
    };
  }
