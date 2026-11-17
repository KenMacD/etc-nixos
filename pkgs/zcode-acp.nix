{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm,
  pnpmConfigHook,
  nodejs,
  makeWrapper,
}:
# Modified from: https://github.com/scotttrinh/dotfiles/blob/799bcba509b27b9f074e41e4957f723a5968c5db/packages/zcode-acp.nix
stdenv.mkDerivation (finalAttrs: {
  pname = "zcode-acp";
  version = "0.88.0";

  src = fetchFromGitHub {
    owner = "william0wang";
    repo = "zcode-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-iDxgaqpLjI3OZOBCsxP8OHbrbKENSPosnJbzjGX6QUk=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 5;
    hash = "sha256-XX7yI7Qkcqn7x/lLPm26t16k6828EE4csmhQTl18myA=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/zcode-acp $out/bin
    cp -r dist node_modules package.json $out/lib/zcode-acp/

    makeWrapper ${nodejs}/bin/node $out/bin/zcode-acp \
      --add-flags $out/lib/zcode-acp/dist/cli.js \
      --prefix PATH : ${lib.makeBinPath [nodejs]} \
      --set-default ZCODE_ACP_SHOW_COMPLETION_STATUS 0
    makeWrapper ${nodejs}/bin/node $out/bin/zcode-acp-server \
      --add-flags $out/lib/zcode-acp/dist/cli.js \
      --add-flags server \
      --prefix PATH : ${lib.makeBinPath [nodejs]} \
      --set-default ZCODE_ACP_SHOW_COMPLETION_STATUS 0
    runHook postInstall
  '';

  meta = {
    description = "ACP (Agent Client Protocol) adapter for ZCode / GLM";
    homepage = "https://github.com/william0wang/zcode-acp";
    license = lib.licenses.mit;
    mainProgram = "zcode-acp";
    platforms = lib.platforms.all;
  };
})
