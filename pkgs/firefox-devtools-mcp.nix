{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  geckodriver,
}:
buildNpmPackage (finalAttrs: {
  pname = "firefox-devtools-mcp";
  version = "0.9.15";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "mozilla";
    repo = "firefox-devtools-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ttABenV+xElKOeck3GB80MiBgW8q46hmR2jPEN5Zcv0=";
  };

  npmDepsHash = "sha256-5zwtZZ6L5c2ZiTWulDlNWvD1fpHP/Su8PB+TT1ds4jQ=";

  nativeBuildInputs = [makeWrapper];

  # The `geckodriver` npm dependency's install script downloads a prebuilt binary from the network,
  # which is unavailable in the sandbox. The server locates geckodriver on PATH first (see
  # src/firefox/core.ts), so skip the install scripts and provide geckodriver from nixpkgs via the
  # wrapper below.
  npmFlags = ["--ignore-scripts"];

  # `npm run build` (tsup) emits dist/index.js, the package's bin entry point.
  postInstall = ''
    wrapProgram $out/bin/firefox-devtools-mcp \
      --prefix PATH : ${lib.makeBinPath [geckodriver]}
  '';

  meta = {
    description = "MCP server exposing Firefox DevTools (via the Firefox Remote Protocol) to AI assistants";
    homepage = "https://github.com/mozilla/firefox-devtools-mcp";
    changelog = "https://github.com/mozilla/firefox-devtools-mcp/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = with lib.licenses; [
      mit
      asl20
    ];
    maintainers = with lib.maintainers; [];
    mainProgram = "firefox-devtools-mcp";
    platforms = lib.platforms.unix;
  };
})
