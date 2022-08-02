self: super:

let
  overridePackage = package: override: overrideAttrs:
    (package.override override).overrideAttrs overrideAttrs;
  swayCommit = "9e879242fd1f1230d34337984cca565d84b932bb";
  swayHash =
    "sha256-CxfEz8Iaot8ShlNqf9aBdVnxnmlN3aUauYqGQsqpkXI=";
  #  https://gitlab.freedesktop.org/wlroots/wlroots
  wlrootsCommit = "30bf8a4303bc5df3cb87b7e6555592dbf8d95cf1";
  wlrootsHash =
    "sha256-0sDD52ARoHUPPA690cJ9ctCOel4TRAn6Yr/IK7euWJc=";
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
    mesonFlags = old.mesonFlags or [ ] ++ mesonFlags;
  });
}
