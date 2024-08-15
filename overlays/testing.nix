self: super:
# This overlay contains hopefully temporary patches.
let
  stdenvDebug = super.stdenvAdapters.keepDebugInfo super.pkgs.clang16Stdenv;
in rec {
  firefox = super.firefox.overrideAttrs (old: {
    libs = old.libs + ":/run/opengl-driver/lib: " + super.intel-gmmlib.outPath + "/lib";
  });

  # TODO: broken on 2024-08-15
  awscli2 = super.stable.awscli2;
  cargo-audit = super.stable.cargo-audit;
  delta = super.stable.delta;
  easyeffects = super.stable.easyeffects;
  kdash = super.stable.kdash;
  quickemu = super.stable.quickemu;
  quickgui = super.stable.quickgui;
  taskwarrior = super.stable.taskwarrior;
  zerotierone = super.stable.zerotierone;

  aichat = super.aichat.overrideAttrs (old: rec {
    version = "0.20.0";
    src = super.fetchFromGitHub {
      owner = "sigoden";
      repo = "aichat";
      rev = "v${version}";
      hash = "sha256-khi5B8nYNK7otWZEs5koCzQaYGZwmGxP3zrMYIt3Ds4=";
    };
    cargoDeps = old.cargoDeps.overrideAttrs (super.lib.const {
      name = "${old.pname}-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-CPDECvODyo7MifNm3EGAdZw+Pew+ET6Y38H7dZtK1vQ=";
    });
  });

  notmuch = super.notmuch.overrideAttrs (old: {
    buildInputs =
      (old.buildInputs or [])
      ++ [
        super.sfsexp
      ];
    preCheck =
      (old.preCheck or "")
      + ''
        rm test/T850-git.sh
      '';
  });

  postman = super.postman.overrideAttrs (old: {
    postFixup = ''
      pushd $out/share/postman
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" postman
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" chrome_crashpad_handler
      for file in $(find . -type f \( -name \*.node -o -name postman -o -name \*.so\* \) ); do
        ORIGIN=$(patchelf --print-rpath $file); \
        patchelf --set-rpath "${super.lib.makeLibraryPath old.buildInputs}:$ORIGIN" $file
      done
      popd
      wrapProgram $out/bin/postman --set PATH ${super.lib.makeBinPath [super.openssl super.xdg-utils]}
    '';
  });

  starship = super.starship.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./starship-aws.patch];
    # Make build faster:
    doCheck = false;
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
