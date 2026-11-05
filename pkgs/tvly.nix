{
  lib,
  python,
  buildPythonApplication,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  nix-update-script,
}:
# Also tries to run 'npx', but I'm not giving it access
let
  tavily-python = buildPythonPackage (finalAttrs': {
    pname = "tavily-python";
    version = "0-unstable-2026-11-05";
    pyproject = true;
    __structuredAttrs = true;

    src = fetchFromGitHub {
      owner = "tavily-ai";
      repo = "tavily-python";
      rev = "46505f119e6ac0f30d63a4dce0ed9f923705ad97";
      hash = "sha256-JKrKHFWcJtNCF9Q6vwmsIyX6myrlTxd7Ti7/x2/9Mi0=";
    };

    build-system = [
      setuptools
    ];

    dependencies = with python.pkgs; [
      openai
      tiktoken
    ];

    pythonImportsCheck = [
      "tavily"
    ];

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "The Tavily Python SDK allows for easy interaction with the Tavily API, offering the full range of our search, extract, crawl, map, and research functionalities directly from your Python programs.";
      homepage = "https://github.com/tavily-ai/tavily-python";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [];
    };
  });
in
  buildPythonApplication (finalAttrs: {
    pname = "tavily-cli";
    version = "0-unstable-2026-11-05";
    pyproject = true;
    __structuredAttrs = true;

    src = fetchFromGitHub {
      owner = "tavily-ai";
      repo = "tavily-cli";
      rev = "a673275091860c8f5b77683cef545a9154da52f5";
      hash = "sha256-ToaUFis7Ofp1pvT3NK9G0ZeKVj2QmKX+QrTj6Jt8wH0=";
    };

    build-system = [
      python.pkgs.hatchling
    ];

    dependencies = with python.pkgs; [
      certifi
      click
      httpx
      packaging
      psutil
      requests
      rich
      tavily-python # uses the in-tree let binding above
      urllib3
    ];

    optional-dependencies = with python.pkgs; {
      dev = [
        pytest
        ruff
      ];
    };

    pythonImportsCheck = [
      "tavily_cli"
    ];

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "";
      homepage = "https://github.com/tavily-ai/tavily-cli";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [];
      mainProgram = "tavily-cli";
    };
  })
