self: super: let
  overridePackage = package: override: overrideAttrs:
    (package.override override).overrideAttrs overrideAttrs;
  stdenvDebug = super.stdenvAdapters.keepDebugInfo super.pkgs.clang16Stdenv;
  mesonFlags = [];
  #mesonFlags = [
  #  "-Db_sanitize=memory"
  #  "-Dc_args=[-fsanitize-memory-track-origins=2,-fno-omit-frame-pointer]"
  #  "-Db_lundef=false"
  # ];
  #mesonFlags = [
  #  "-Db_sanitize=address"
  #  "-Db_lundef=false"
  #];
in let
  waylandDbgFrm = super:
    overridePackage super.wayland {stdenv = stdenvDebug;}
    (old: {mesonBuildType = "debug";});
in let
  wlroots =
    overridePackage super.wlroots {
      stdenv = stdenvDebug;
      wayland = waylandDbgFrm super;
    } (old: {
      mesonBuildType = "debug";
      mesonFlags = old.mesonFlags or [] ++ mesonFlags;

      version = "0.17.2-dev";
      src = super.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "wlroots";
        repo = "wlroots";
        rev = "63e2f2e28fc1f037a0117bb85d37f84397345c71";
        hash = "sha256-my9x7+zNRUDaGNAT3fQivjzahq2kVxDWsDRW4Vp4Gas=";
      };
    });
in {
  swaylock =
    overridePackage super.swaylock {
      stdenv = stdenvDebug;
      wayland = waylandDbgFrm super;
    } (old: {
      mesonBuildType = "debug";
      mesonFlags = (old.mesonFlags or []) ++ mesonFlags;
    });
  sway-unwrapped =
    overridePackage super.sway-unwrapped {
      stdenv = stdenvDebug;
      wayland = waylandDbgFrm super;
      wlroots = wlroots;
    } (old: {
      mesonBuildType = "debug";
      mesonFlags = (old.mesonFlags or []) ++ mesonFlags;
    });
}
