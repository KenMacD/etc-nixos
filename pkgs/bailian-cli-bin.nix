# Prebuilt binary packaging of the Alibaba Cloud Model Studio (百炼) CLI.
#
# The upstream "binary" release is a Bun-compiled, dynamically linked ELF that
# needs nothing but glibc (libc/libm/libpthread/libdl + ld-linux), so
# autoPatchelfHook + stdenv.cc.libc is the whole story — no FHS tricks.
#
# Manifest: https://bailian-wiki.oss-cn-hangzhou.aliyuncs.com/release/manifest.json
# (Upstream ships no linux-arm64 binary; the install script says to use npm there.)
{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "bailian-cli-bin";
  version = "2.10.1";

  src = fetchurl {
    url = "https://bailian-wiki.oss-cn-hangzhou.aliyuncs.com/release/v${finalAttrs.version}/bl-${finalAttrs.version}-linux-x64.zip";
    hash = "sha256-BjNJ+leCbLOVTvVvJAR7DO0ANK3UOO4dX41ZNxkCFX8=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [stdenv.cc.libc];

  unpackCmd = "unzip $src";
  sourceRoot = ".";

  # Bun embeds its runtime in a section after the ELF; stripping corrupts it
  # (same as nixpkgs' bun package).
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bl-${finalAttrs.version}-linux-x64 $out/bin/bl
    # `bailian` is an upstream alias, not our invention: install.sh symlinks both.
    ln -s bl $out/bin/bailian
    runHook postInstall
  '';

  # Updates happen via NixOS, not the CLI: silence the built-in update
  # notifier (NO_UPDATE_NOTIFIER=1 is the only kill switch it honours;
  # --set-default keeps it overridable). `bailian` symlinks to `bl` and
  # inherits the wrapper.
  postFixup = ''
    wrapProgram $out/bin/bl --set-default NO_UPDATE_NOTIFIER 1
  '';

  # Footgun: an explicit `bl update` bypasses the wrapper and downloads into
  # ~/.local/share/bailian-cli, which shadows this package on PATH. Don't
  # run it; bump `version` instead.

  meta = {
    # Upstream package.json and the GitHub repo LICENSE both say Apache-2.0.
    description = "Official Model Studio CLI（阿里云百炼 CLI）— prebuilt Bun binary";
    homepage = "https://bailian.aliyun.com/";
    license = lib.licenses.asl20;
    mainProgram = "bl";
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
  };
})
