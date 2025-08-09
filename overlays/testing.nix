self: super:
# This overlay contains hopefully temporary patches.
let
  stdenvDebug = super.stdenvAdapters.keepDebugInfo super.pkgs.clang16Stdenv;
in rec {
  firefox = super.firefox.overrideAttrs (old: {
    libs = old.libs + ":/run/opengl-driver/lib: " + super.intel-gmmlib.outPath + "/lib";
  });

  # TODO: Does not apply 2024-03-30
  #  # Allow waydroid to install from a local android image
  #  waydroid = super.waydroid.overridePythonAttrs (old: rec {
  #    version = "1.3.4";
  #    src = super.fetchFromGitHub {
  #      owner = old.pname;
  #      repo = old.pname;
  #      rev = version;
  #      sha256 = "sha256-0GBob9BUwiE5cFGdK8AdwsTjTOdc+AIWqUGN/gFfOqI=";
  #    };
  #    patches = (old.patches or []) ++ [./waydroid-image-path.patch];
  #  });
}
