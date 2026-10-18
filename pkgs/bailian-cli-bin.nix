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
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "bailian-cli-bin";
  version = "2.3.1";

  src = fetchurl {
    url = "https://bailian-wiki.oss-cn-hangzhou.aliyuncs.com/release/v${finalAttrs.version}/bl-${finalAttrs.version}-linux-x64.zip";
    hash = "sha256-rsLsWmFUDLBN7syfatqMkoyG3Tf4x48NDkstlpgDUCU=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
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

  # Footgun: `bl update` self-updates by downloading into ~/.local/share/bailian-cli.
  # The store path is read-only so it can't corrupt the package, but a copy it drops
  # in $HOME would shadow this one on PATH. Don't run it; bump `version` instead.

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
