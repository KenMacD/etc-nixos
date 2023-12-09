{
  lib,
  fenix,
  makeRustPlatform,
  cargo-pgrx,
  fetchFromGitHub,
  buildPgrxExtension,
  postgresql,
  curl,
  pkg-config,
  openssl,
  zlib,
  stdenv,
  darwin,
}: let
  version = "0.1.11";
  src = fetchFromGitHub {
    owner = "tensorchord";
    repo = "pgvecto.rs";
    rev = "v${version}";
    hash = "sha256-GOOquwT3EJB6sE5RaaEb0BiqLmdceBW0VT7Qv8g74E8=";
  };

  # TODO: use flake input if reused

  toolchain = fenix.fromToolchainFile {
    file = src + "/rust-toolchain.toml";
    sha256 = "sha256-cbsA/sdnWRA63EBChHtJvGGcACj2CxG8FmE+M57xnl0=";
  };

  rustPlatform = makeRustPlatform {
    rustc = toolchain;
    cargo = toolchain;
  };
in
  buildPgrxExtension.override {
    inherit rustPlatform;
    cargo-pgrx = cargo-pgrx.override {inherit rustPlatform;};
  } rec {
    inherit postgresql version;

    pname = "pgvecto-rs";

    src = fetchFromGitHub {
      owner = "tensorchord";
      repo = "pgvecto.rs";
      rev = "v${version}";
      hash = "sha256-GOOquwT3EJB6sE5RaaEb0BiqLmdceBW0VT7Qv8g74E8=";
    };

    cargoLock = {
      lockFile = src + "/Cargo.lock";
      outputHashes = {
        "openai_api_rust-0.1.8" = "sha256-os5Y8KIWXJEYEcNzzT57wFPpEXdZ2Uy9W3j5+hJhhR4=";
      };
    };

    nativeBuildInputs = [
      curl
      pkg-config
      rustPlatform.bindgenHook
    ];

    buildInputs =
      [
        curl
        openssl
        zlib
      ]
      ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.CoreFoundation
        darwin.apple_sdk.frameworks.IOKit
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];

    meta = with lib; {
      description = "Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
      homepage = "https://github.com/tensorchord/pgvecto.rs/";
      license = licenses.asl20;
      maintainers = with maintainers; [];
      mainProgram = "pgvecto-rs";
    };
  }
