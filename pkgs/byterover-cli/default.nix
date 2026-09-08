{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage (finalAttrs: {
  pname = "byterover-cli";
  version = "3.7.1";

  src = fetchFromGitHub {
    owner = "KenMacD";
    repo = "byterover-cli";
    # Add host and bind envs
    rev = "b72a1dc7b2007a349702278750413aca7e219f24";
    hash = "sha256-Ylyd7mONjuDhrsQlIwkF6jr+QYRwsRgY4nLgW/Ens04=";
  };

  patches = [
    ./glm51.patch
  ];

  npmDepsHash = "sha256-7HlBPs3M8zs++qON1AaNbvINlKzL407fgEBV1YbMOKQ=";

  nodejs = nodejs_22;

  makeCacheWritable = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/byterover-cli
    cp -r . $out/lib/node_modules/byterover-cli/

    mkdir -p $out/bin
    ln -s $out/lib/node_modules/byterover-cli/bin/run.js $out/bin/brv
    chmod +x $out/lib/node_modules/byterover-cli/bin/run.js

    # Production environment config (not included in GitHub source tarball)
    cat > $out/lib/node_modules/byterover-cli/.env.production << 'EOF'
    BRV_IAM_BASE_URL=https://iam.byterover.dev
    BRV_COGIT_BASE_URL=https://v3-cgit.byterover.dev
    BRV_GIT_REMOTE_BASE_URL=https://byterover.dev
    BRV_LLM_BASE_URL=https://llm.byterover.dev
    BRV_WEB_APP_URL=https://app.byterover.dev
    EOF

    runHook postInstall
  '';

  meta = {
    description = "ByteRover CLI (brv) - The portable memory layer for autonomous coding agents";
    homepage = "https://github.com/campfirein/byterover-cli";
    changelog = "https://github.com/campfirein/byterover-cli/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.elastic20;
    maintainers = with lib.maintainers; [];
    mainProgram = "brv";
    platforms = lib.platforms.all;
  };
})
