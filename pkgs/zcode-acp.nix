{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  nodejs,
  nix-update-script,
  writableTmpDirAsHomeHook,
  makeBinaryWrapper,
  zcode,
}:
# zcode-acp pins the ZCode artifact by sha256 (CURRENT_ZCODE_ARTIFACT in the
# compiled bundle); doctor re-verifies the hash at runtime.
assert zcode.version == "3.11.2";
  stdenv.mkDerivation (finalAttrs: {
    pname = "zcode-acp";
    version = "0.3.2";
    __structuredAttrs = true;
    strictDeps = true;

    src = fetchFromGitHub {
      owner = "supermomonga";
      repo = "zcode-acp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-iFdCVJIx+gKmplyAlus96CD29+prEneYhS+4j8YdqPc=";
    };

    node_modules = stdenvNoCC.mkDerivation {
      pname = "${finalAttrs.pname}-node_modules";
      inherit (finalAttrs) version src;

      impureEnvVars =
        lib.fetchers.proxyImpureEnvVars
        ++ [
          "GIT_PROXY_COMMAND"
          "SOCKS_SERVER"
        ];

      nativeBuildInputs = [
        bun
        writableTmpDirAsHomeHook
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

        bun install \
          --backend=copyfile \
          --cpu="*" \
          --frozen-lockfile \
          --ignore-scripts \
          --no-progress \
          --os="*"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        find . -type d -name node_modules -exec cp -R --parents {} $out \;

        runHook postInstall
      '';

      dontFixup = true;

      outputHash = "sha256-mScgLBr3/ssLT4Q73RS2LGFlh+j0VAS3JJkHLiu0J/0=";
      outputHashMode = "recursive";
    };

    nativeBuildInputs = [
      bun
      nodejs
      writableTmpDirAsHomeHook
      makeBinaryWrapper
    ];

    # bun build --compile appends the JS bundle to the bun binary; strip would
    # remove it and the executable would fall back to plain bun CLI behaviour.
    dontStrip = true;

    configurePhase = ''
      runHook preConfigure

      cp -R ${finalAttrs.node_modules}/. .
      patchShebangs node_modules

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      bun run build

      runHook postBuild
    '';

    doCheck = true;

    checkPhase = ''
      runHook preCheck

      bun run typecheck
      bun test

      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 dist/zcode-acp $out/bin/zcode-acp

      runHook postInstall
    '';

    # Point discovery at the pinned zcode derivation; --set-default keeps the
    # env var overridable by callers.
    postInstall = ''
      wrapProgram "$out/bin/zcode-acp" \
        --set-default ZCODE_ACP_ZCODE_INSTALL "${zcode}/lib/ZCode"
    '';

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "An ACP Agent wrapper for ZCode";
      homepage = "https://github.com/supermomonga/zcode-acp";
      changelog = "https://github.com/supermomonga/zcode-acp/releases/tag/${finalAttrs.src.tag}";
      # TODO: placeholder until the project publishes a LICENSE file (none in
      # the repo as of v0.3.2, see docs/07-security-licensing.md)
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [];
      mainProgram = "zcode-acp";
      platforms = lib.platforms.all;
    };
  })
