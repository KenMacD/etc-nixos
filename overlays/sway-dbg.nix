self: super:

let
  overridePackage = package: override: overrideAttrs:
    (package.override override).overrideAttrs overrideAttrs;
  swayCommit = "07bfeb2abcb46b5f1472d53963478fa0714fb5b1";
  swayHash =
    "sha256-JfN0t7ZemuopN+JoPCVuLZUBwAlGdFEIRvqqB6lZQSQ=";   
  #  https://gitlab.freedesktop.org/wlroots/wlroots
  wlrootsCommit = "fd0b0276c9ecc159549acff48b932b83ec3b4f12";
  wlrootsHash =
    "sha256-Kw0MG4rXdTnbndVLLCNwkXDmNszwdQZmm7pwI1R3Kds=";
  stdenvDebug = super.stdenvAdapters.keepDebugInfo super.pkgs.clang13Stdenv;
  mesonFlags = [ ];
  #  mesonFlags = [
  #    "-Db_sanitize=memory"
  #    "-Dc_args=[-fsanitize-memory-track-origins=2,-fno-omit-frame-pointer]"
  #    "-Db_lundef=false"
  #  ];
  #  mesonFlags = [
  #    "-Db_sanitize=address"
  #    "-Db_lundef=false"
  #  ];
in let
  waylandDbgFrm = super:
    overridePackage super.wayland { stdenv = stdenvDebug; }
    (old: { mesonBuildType = "debug"; });
in let
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
      sha256 = wlrootsHash;
    };
    buildInputs = old.buildInputs ++ [ super.pkgs.pcre2 ];
    mesonBuildType = "debug";
    mesonFlags = old.mesonFlags or [ ] ++ mesonFlags;
  });
in {
  swaylock = overridePackage super.swaylock {
    stdenv = stdenvDebug;
    wayland = waylandDbgFrm super;
  } (old: {
    mesonBuildType = "debug";
    mesonFlags = (old.mesonFlags or [ ]) ++ mesonFlags;
  });
  sway-unwrapped = overridePackage super.sway-unwrapped {
    stdenv = stdenvDebug;
    wayland = waylandDbgFrm super;
    wlroots = wlroots;
  } (old: {
    version = swayCommit;
    src = super.fetchFromGitHub {
      owner = "swaywm";
      repo = "sway";
      rev = swayCommit;
      sha256 = swayHash;
    };
    buildInputs = old.buildInputs
      ++ [ super.pkgs.pcre2 super.pkgs.xorg.xcbutilwm ];
    mesonBuildType = "debug";
    mesonFlags = (old.mesonFlags or [ ]) ++ mesonFlags;
  });
}
