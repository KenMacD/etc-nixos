# Temporary version bump to include fix for espanso opening a rainbow window
# TODO: remove after 2.2.2 available in nixpkgs
{
  lib,
  coreutils,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  extra-cmake-modules,
  bash,
  dbus,
  libX11,
  libXi,
  libXtst,
  libnotify,
  libxkbcommon,
  openssl,
  xclip,
  xdotool,
  setxkbmap,
  wl-clipboard,
  wxGTK32,
  makeWrapper,
  stdenv,
  waylandSupport ? false,
  x11Support ? stdenv.isLinux,
  testers,
#  espanso,
}:
# espanso does not support building with both X11 and Wayland support at the same time
assert stdenv.isLinux -> x11Support != waylandSupport;
  rustPlatform.buildRustPackage rec {
    pname = "espanso";
    version = "2.2.1-db97658";

    src = fetchFromGitHub {
      owner = "espanso";
      repo = "espanso";
      rev = "db97658d1d80697a635b57801696c594eacf057b";
      hash = "sha256-4y5yHFfA8SmtSJVC2YleoHCUXkgqee+k9A2pRUzqzDo=";
    };

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "yaml-rust-0.4.6" = "sha256-wXFy0/s4y6wB3UO19jsLwBdzMy7CGX4JoUt5V6cU7LU=";
      };
    };

    nativeBuildInputs = [
      extra-cmake-modules
      pkg-config
      makeWrapper
      wxGTK32
    ];

    # Ref: https://github.com/espanso/espanso/blob/78df1b704fe2cc5ea26f88fdc443b6ae1df8a989/scripts/build_binary.rs#LL49C3-L62C4
    buildNoDefaultFeatures = true;
    buildFeatures =
      [
        "modulo"
      ]
      ++ lib.optionals waylandSupport [
        "wayland"
      ]
      ++ lib.optionals stdenv.isLinux [
        "vendored-tls"
      ];

    buildInputs =
      [
	bash
        wxGTK32
      ]
      ++ lib.optionals stdenv.isLinux [
        openssl
        dbus
        libnotify
        libxkbcommon
      ]
      ++ lib.optionals waylandSupport [
        wl-clipboard
      ]
      ++ lib.optionals x11Support [
        libXi
        libXtst
        libX11
        xclip
        xdotool
      ];

    postPatch = ''
      cp ${./Cargo.lock} Cargo.lock
    '';

    # Some tests require networking
    doCheck = false;

    postInstall =
      ''
        wrapProgram $out/bin/espanso \
          --prefix PATH : ${lib.makeBinPath (
          lib.optionals stdenv.isLinux [
	    bash
            libnotify
            setxkbmap
          ]
          ++ lib.optionals waylandSupport [
            wl-clipboard
          ]
          ++ lib.optionals x11Support [
            xclip
          ]
        )}
      '';

#    passthru.tests.version = testers.testVersion {
#      package = espanso;
#    };
#
    meta = with lib; {
      description = "Cross-platform Text Expander written in Rust";
      mainProgram = "espanso";
      homepage = "https://espanso.org";
      license = licenses.gpl3Plus;
      platforms = platforms.unix;

      longDescription = ''
        Espanso detects when you type a keyword and replaces it while you're typing.
      '';
    };
  }
