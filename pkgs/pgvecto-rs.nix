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
  clang_16,
  darwin,
}: let
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "KenMacD";
    repo = "pgvecto.rs";
    rev = "00a3912ffc8d59352887999d27f0b266e6ddd5c5";
    hash = "sha256-ySbKGjSuxS25RrSBBMFB8y0xGRKyWm7A5FHEKR30+Ok=";
  };

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
    inherit postgresql version src;

    pname = "pgvecto-rs";

    postPatch = ''
      substituteInPlace crates/c/build.rs \
        --replace "/usr/bin/clang-16" "${clang_16}/bin/clang"
    '';

    cargoLock = {
      lockFile = src + "/Cargo.lock";
      outputHashes = {
        "openai_api_rust-0.1.8" = "sha256-os5Y8KIWXJEYEcNzzT57wFPpEXdZ2Uy9W3j5+hJhhR4=";
        "std_detect-0.1.5" = "sha256-RwWejfqyGOaeU9zWM4fbb/hiO1wMpxYPKEjLO0rtRmU=";
      };
    };

    nativeBuildInputs = [
      curl
      pkg-config
      rustPlatform.bindgenHook
      clang_16
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
