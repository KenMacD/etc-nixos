# Source-built variant of the Alibaba Cloud Model Studio (百炼) CLI, from the
# upstream GitHub repo (modelstudioai/cli). Not installed on any host; kept as
# an alternative to the prebuilt binary in bailian-cli-bin.nix — build with
# `nix build .#bailian-cli` if ever needed.
{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  fetchPnpmDeps,
  jq,
  nix-update-script,
  versionCheckHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "modelstudioai-cli";
  version = "2.3.1";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "modelstudioai";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wZ0TlV96cf07oKcTOOj1N5x8WRbBiRlfvDKcIt9MgSs=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    pnpmConfigHook
    jq
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-s+UlYj4uZ6p3pb82c0aSjkFsPv/VU5eDMRrK3cwhKoA=";
  };

  nativeInstallCheckInputs = [versionCheckHook];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/bailian";
  versionCheckProgramArg = "--version";

  # `vp pack` bundles each package from the TypeScript sources of the workspace
  # packages (their dev exports point at src/), but the CLI entry bundle keeps
  # `bailian-cli-runtime`/`bailian-cli-commands` as external imports, mirroring
  # the separately published npm packages. Build all of them (topological
  # order), then install the CLI together with a real node_modules tree
  # containing the workspace deps (with their publishConfig exports applied,
  # as `npm publish` would).
  buildPhase = ''
    runHook preBuild
    pnpm --filter "bailian-cli..." run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    libdir=$out/lib/bailian-cli
    mkdir -p $libdir/dist
    cp -r packages/cli/dist/. $libdir/dist/
    install -Dm644 packages/cli/package.json $libdir/package.json

    # Prod-only, hoisted (symlink-free) node_modules for bailian-cli and its
    # workspace dependencies. CI=true avoids the interactive modules-purge
    # prompt (no TTY in the build sandbox).
    # NOTE: `pnpm deploy` was evaluated and rejected: --legacy needs registry
    # access, and the pnpm-10 injected mode still ships dev-mode exports (so
    # the publishConfig rewrite below remains necessary), runs the package's
    # network-fetching postinstall script, and leaves a broken .bin symlink.
    CI=true pnpm --filter bailian-cli... install --prod --ignore-scripts --offline \
      --config.node-linker=hoisted
    mkdir -p $libdir/node_modules
    cp -rL node_modules/. $libdir/node_modules/
    # Workspace dependencies are linked only in the dependent's node_modules,
    # not hoisted to the root.
    cp -rL packages/cli/node_modules/. $libdir/node_modules/
    # The hoisted install leaves pnpm's old symlink farm and state files
    # behind; nothing references them anymore.
    rm -rf $libdir/node_modules/.pnpm $libdir/node_modules/.bin \
      $libdir/node_modules/.modules.yaml $libdir/node_modules/.pnpm-workspace-state-v1.json

    # Workspace packages ship with dev-mode exports pointing at src/*.ts;
    # apply the publishConfig overrides that `npm publish` would apply, to
    # every copy in the tree (hoisted layouts can nest duplicates) and to
    # the CLI's own manifest.
    find $libdir -name package.json -not -path "*/dist/*" -print0 |
      while IFS= read -r -d "" pj; do
        jq 'if (.name // "" | test("^bailian-cli(-|$)")) then
              . + ((.publishConfig // {}) | del(.registry, .access))
              | del(.publishConfig, .scripts, .devDependencies)
            else . end' "$pj" > "$pj.new" && mv "$pj.new" "$pj"
      done

    # The entry bundle carries a `#!/usr/bin/env node` shebang; point it at
    # the nix node directly (a runtime PATH lookup for `env node` would break
    # in environments without node on PATH).
    substituteInPlace $libdir/dist/bailian.mjs \
      --replace-fail "#!/usr/bin/env node" "#!${nodejs_22}/bin/node"
    mkdir -p $out/bin
    ln -s $libdir/dist/bailian.mjs $out/bin/bailian
    ln -s bailian $out/bin/bl

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "CLI for Alibaba Cloud Model Studio (Bailian) built for AI agent frameworks";
    homepage = "https://github.com/modelstudioai/cli";
    changelog = "https://github.com/modelstudioai/cli/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [];
    mainProgram = "bailian";
    platforms = lib.platforms.all;
  };
})
