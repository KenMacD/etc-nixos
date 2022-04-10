self: super:

let
  overridePackage = package: override: overrideAttrs:
    (package.override override).overrideAttrs overrideAttrs;
  swayCommit = "8f036b6f788e45a36d3126a661913dd38008cc41";
  swayHash =
    "sha256-FfLHD/hhel/42mUz47k5VuXp+Sr6V/tPYM+XZgMn3oI="; # super.lib.fakeSha256;
  wlrootsCommit = "2e14bed9f790c29146b0eee70eab7d8c704876e9";
  wlrootsHash =
    "sha256-FlxBo7wgvLryC+OcvIBiKyk7i0O1/WyVs5UZdU6iXfE="; # super.lib.fakeSha256;
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
    buildInputs = old.buildInputs ++ [ super.pkgs.pcre2 ];
    mesonBuildType = "debug";
    mesonFlags = old.mesonFlags or [ ] ++ mesonFlags;
  });
}
