{
  lib,
  fetchurl,
  appimageTools,
  coreutils,
  util-linux,
}: let
  pname = "autoclaw";
  version = "2.0.3";

  src = fetchurl {
    url = "https://autoglm-public-oss.z.ai/zwork/updates/production/official/linux-x64/AutoClaw-${version}-x64.AppImage";
    hash = "sha256-xmO5VB7ZGXDjftmbIj/vehBkUXsr6C7wVKrLcjvjq+w=";
  };

  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # AppRun's shebang is /usr/bin/env bash, and it probes unprivileged user
    # namespaces with unshare to decide whether Electron may keep its
    # sandbox. Without these in the FHS env it either fails to start or
    # silently falls back to --no-sandbox.
    extraPkgs = p: [
      p.coreutils
      p.util-linux
    ];

    extraInstallCommands = ''
      install -Dm644 ${contents}/AutoClaw2.desktop $out/share/applications/autoclaw.desktop
      substituteInPlace $out/share/applications/autoclaw.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=autoclaw %U' \
        --replace-fail 'Icon=AutoClaw2' 'Icon=autoclaw'
      install -Dm644 ${contents}/usr/share/icons/hicolor/512x512/apps/AutoClaw2.png \
        $out/share/icons/hicolor/512x512/apps/autoclaw.png
    '';

    meta = with lib; {
      description = "Desktop AI cowork platform powered by the OpenClaw gateway";
      homepage = "https://autoclaw.z.ai/";
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
