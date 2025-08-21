{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  playwright,
}:
# Borrowed from https://github.com/natsukium/mcp-servers-nix/blob/9689f2309fa9f0b154ddef38bdbe140b3de0daa5/pkgs/official/playwright/default.nix
# Added envs
# TODO: {playwright.components.chromium}/chrome-linux/chrom
# For now using --executable-path /nix/store/43vaim7vj5hva1ravhmb0ziwpzasdr41-playwright-browsers/chromium-1169/chrome-linux/chrome
let
  # 2025-06-20: webkit is broken
  browsers = playwright.browsers.override {
    withWebkit = false;
  };
in
  buildNpmPackage rec {
    pname = "playwright-mcp";
    version = "0.0.34";

    src = fetchFromGitHub {
      owner = "microsoft";
      repo = "playwright-mcp";
      tag = "v${version}";
      hash = "sha256-SGSzX41D9nOTsGiU16tRFXgarWgePRsNWIcEnNGH0lQ=";
    };

    npmDepsHash = "sha256-+6HmuR1Z5cJkoZq/vsFq6wNsYpZeDS42wwmh3hEgJhM=";

    postFixup = ''
      wrapProgram $out/bin/mcp-server-playwright \
          --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD "1" \
          --set PLAYWRIGHT_BROWSERS_PATH ${browsers} \
          --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS "true"
    '';

    meta = {
      description = "Playwright MCP server";
      homepage = "https://github.com/microsoft/playwright-mcp";
      changelog = "https://github.com/microsoft/playwright-mcp/releases/tag/v${version}";
      license = lib.licenses.asl20;
      mainProgram = "mcp-server-playwright";
    };
  }
