{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  nodejs_24,
}:
# From https://github.com/numtide/nix-ai-tools/blob/71492902260665ab6a4d4083487215bfc2ca0ad6/packages/claude-code-router/package.nix
stdenv.mkDerivation rec {
  pname = "claude-code-router";
  version = "1.0.61";

  src = fetchzip {
    url = "https://registry.npmjs.org/@musistudio/claude-code-router/-/claude-code-router-${version}.tgz";
    hash = "sha256-eLzSi8bgF64Pwqrd/ftLkVSMBVLEA2A0HxPOP2J1M2Y=";
  };

  nativeBuildInputs = [makeWrapper nodejs_24];

  postBuild = ''
  '';
  installPhase = ''
    runHook preInstall

    # The npm package already contains built files
    mkdir -p $out/bin
    cp $src/dist/cli.js $out/bin/ccr
    chmod +x $out/bin/ccr

    wrapProgram $out/bin/ccr --prefix PATH : ${
      lib.makeBinPath [
        nodejs_24
      ]
    }

    # Install the WASM file in the same directory as the CLI
    cp $src/dist/tiktoken_bg.wasm $out/bin/

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Use Claude Code without an Anthropics account and route it to another LLM provider";
    homepage = "https://github.com/musistudio/claude-code-router";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "ccr";
  };
}
