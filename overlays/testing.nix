self: super:
# This overlay contains hopefully temporary patches.
rec {
  # Runnin copilot in vscodium, see bug: https://github.com/VSCodium/vscodium/issues/888
  vscodium = super.vscodium.overrideAttrs (old: rec {
    postInstall =
      (old.postInstall or "")
      + ''
        substituteInPlace $out/lib/vscode/resources/app/product.json \
          --replace '"GitHub.copilot": ["inlineCompletionsAdditions"],' \
             '"GitHub.copilot": ["inlineCompletions","inlineCompletionsNew","inlineCompletionsAdditions","textDocumentNotebook","interactive","terminalDataWriteEvent"],' \
          --replace '"GitHub.copilot-nightly": ["inlineCompletionsAdditions"],' \
             '"GitHub.copilot-nightly": ["inlineCompletions","inlineCompletionsNew","inlineCompletionsAdditions","textDocumentNotebook","interactive","terminalDataWriteEvent"],' \
      '';
  });

  notmuch = super.notmuch.overrideAttrs (old: {
    buildInputs =
      (old.buildInputs or [])
      ++ [
        super.sfsexp
      ];
    preCheck = (old.preCheck or "") + ''
      rm test/T850-git.sh
    '';
  });

  # Enable experimental libkrun in crun
  crun = super.crun.overrideAttrs (old: {
    buildInputs =
      (old.buildInputs or [])
      ++ [
        super.libkrun
      ];
    configureFlags =
      (old.configureFlags or [])
      ++ [
        "--with-libkrun"
      ];
    postFixup =
      (old.postFixup or "")
      + ''
        ln -s $out/bin/crun $out/bin/krun
        patchelf --set-rpath "$(patchelf --print-rpath $out/bin/crun):${super.libkrun.out}/lib" $out/bin/crun
      '';
  });

  # Allow waydroid to install from a local android image
  waydroid = super.waydroid.overridePythonAttrs (old: rec {
    version = "1.3.4";
    src = super.fetchFromGitHub {
      owner = old.pname;
      repo = old.pname;
      rev = version;
      sha256 = "sha256-0GBob9BUwiE5cFGdK8AdwsTjTOdc+AIWqUGN/gFfOqI=";
    };
    patches = (old.patches or []) ++ [./waydroid-image-path.patch];
  });
}
