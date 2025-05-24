{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  playwright,
}:
# Borrowed from https://github.com/natsukium/mcp-servers-nix/blob/9689f2309fa9f0b154ddef38bdbe140b3de0daa5/pkgs/official/playwright/default.nix
# Version bump, and tag for 0.0.26 is a little inconsistent v.0.0.26
# Added envs
buildNpmPackage rec {
  pname = "playwright-mcp";
  version = "0.0.26";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-mcp";
    tag = "v.${version}";
    hash = "sha256-ubEVLNCLsTlOzal4C/r2RDxjCpteLU8NUQwJo0SNLbA=";
  };

  npmDepsHash = "sha256-fWGYJIfs00s5VupdEyL4tzN70ksAs8fSV+L2Q9JB9YQ=";

  postFixup = ''
    wrapProgram $out/bin/mcp-server-playwright \
        --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD "1" \
        --set PLAYWRIGHT_BROWSERS_PATH ${playwright.browsers} \
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
