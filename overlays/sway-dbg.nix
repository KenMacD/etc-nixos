self: super:

let
  overridePackage = package: override: overrideAttrs:
    (package.override override).overrideAttrs overrideAttrs;
  swayCommit = "440d0bc22d57b8b0b21a8acbf127243b8d08cfae";
  wlrootsCommit = "aaf787ee5650e77f0bda4dea8e3ba8325e0e6b39";
  stdenvDebug = super.stdenvAdapters.keepDebugInfo super.pkgs.clang13Stdenv;
in let
  waylandDbgFrm = super:
    overridePackage super.wayland {
      stdenv = stdenvDebug;
    } (old: {
      mesonBuildType = "debug";
      mesonFlags = old.mesonFlags or [ ]
        ++ [ "-Db_sanitize=address" "-Db_lundef=false" ];
    });
in {
      wlroots = overridePackage super.wlroots {
        stdenv = stdenvDebug;
        wayland = waylandDbgFrm super;
      } (old: {
        version = wlrootsCommit;
        src = super.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "wlroots";
          repo = "wlroots";
          rev = wlrootsCommit;
          sha256 = "sha256-5cIO7ctznUrN8Dh1PbmQFMcF1gv5RaYgi8yHBrT+FJ4="; # super.lib.fakeSha256;
        };
        buildInputs = old.buildInputs ++ [ super.pkgs.pcre2 ];
        mesonBuildType = "debug";
        mesonFlags = old.mesonFlags or [ ]
          ++ [ "-Db_sanitize=address" "-Db_lundef=false" ];
      });
      sway-unwrapped = overridePackage super.sway-unwrapped {
        stdenv = stdenvDebug;
        wayland = waylandDbgFrm super;
      } (old: {
        version = swayCommit;
        src = super.fetchFromGitHub {
          owner = "swaywm";
          repo = "sway";
          rev = swayCommit;
          sha256 = "sha256-ZtIecq86v3g4wT+57eixk4+Me86gYx+mfarurNnl2gE="; # super.lib.fakeSha256;
        };
#        patches = (old.patches or [ ]) ++ [ ./sway-ld-preload.patch ];
        buildInputs = old.buildInputs ++ [ super.pkgs.pcre2 ];
        mesonBuildType = "debug";
        mesonFlags = old.mesonFlags or [ ]
          ++ ["-Db_sanitize=address" "-Db_lundef=false" ];
      });
    }
