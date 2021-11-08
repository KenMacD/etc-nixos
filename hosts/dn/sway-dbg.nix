{ config, lib, pkgs, ... }:
with lib;

let
  overridePackage = package: override: overrideAttrs:
    (package.override override).overrideAttrs overrideAttrs;
  newMesonFrm = super:
    super.meson.overrideAttrs (old: {
      version = "0.59.2";
      src = super.python3.pkgs.fetchPypi {
        pname = "meson";
        version = "0.59.2";
        sha256 = "sha256-E97lSae6dYt+M853GfKNHTN6mNENN4pHeczJlvWi/Ek=";
      };
      patches = (take 2 old.patches) ++ [ ./gir-fallback-path.patch ]
        ++ (drop 3 old.patches);
    });
in let
  waylandDbgFrm = super:
    overridePackage super.wayland {
      stdenv = super.stdenvAdapters.keepDebugInfo pkgs.clang11Stdenv;
      meson = newMesonFrm super;
    } (old: {
      mesonFlags = old.mesonFlags or [ ]
        ++ [ "-Db_sanitize=address" "-Db_lundef=false" ];
    });
in {
  environment.systemPackages = [ pkgs.llvmPackages_latest.compiler-rt ];
  programs.sway.extraSessionCommands = ''
    # Export will affect all programs so removed in patch
    export LD_PRELOAD="${pkgs.llvmPackages_latest.compiler-rt}/lib/linux/libclang_rt.scudo-x86_64.so"
  '';
  environment.variables = {
    SCUDO =
      "${pkgs.llvmPackages_latest.compiler-rt}/lib/linux/libclang_rt.scudo-x86_64.so";
  };
  nixpkgs.overlays = [
    (self: super: {
      wlroots = overridePackage super.wlroots {
        stdenv = super.stdenvAdapters.keepDebugInfo pkgs.clang11Stdenv;
        meson = newMesonFrm super;
        wayland = waylandDbgFrm super;
      } (old: {
        version = "3dc99ed2819465d3508ab1cfd7bd8e9857936b9a";
        src = super.fetchFromGitHub {
          owner = "swaywm";
          repo = "wlroots";
          rev = "f42e3d28daf3d7e2a86896d80018f85ab28ae6bb";
          sha256 = "18d7yyn2444f2524y6gfmlngl2xx173nk0l2hk9a3zlkj3734gfg";
        };
        nativeBuildInputs = old.nativeBuildInputs
          ++ [ pkgs.vulkan-loader pkgs.vulkan-headers pkgs.glslang ];
        mesonFlags = old.mesonFlags or [ ]
          ++ [ "-Db_sanitize=address" "-Db_lundef=false" ];
      });
    })
    (self: super: {
      sway-unwrapped = overridePackage super.sway-unwrapped {
        stdenv = super.stdenvAdapters.keepDebugInfo pkgs.clang11Stdenv;
        meson = newMesonFrm super;
        wayland = waylandDbgFrm super;
      } (old: {
        version = "215787e8b28d4e52d97bdcadd4b64305c7a62ac5";
        src = super.fetchFromGitHub {
          owner = "swaywm";
          repo = "sway";
          rev = "215787e8b28d4e52d97bdcadd4b64305c7a62ac5";
          sha256 = "1dxkc1jd8wx7pybizw2lvx1g2ns4ncq7zbhciy9nff5hp0l5yjad";
        };
        patches = (old.patches or [ ]) ++ [ ./sway-ld-preload.patch ];
        mesonFlags = old.mesonFlags or [ ]
          ++ [ "-Db_sanitize=address" "-Db_lundef=false" ];
      });
    })
  ];
}
