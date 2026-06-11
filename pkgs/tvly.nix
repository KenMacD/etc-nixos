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
    version = "0-unstable-2026-06-10";
    pyproject = true;
    __structuredAttrs = true;

    src = fetchFromGitHub {
      owner = "tavily-ai";
      repo = "tavily-python";
      rev = "bf176448a0d773871e01e88320669c9cfbb1cb82";
      hash = "sha256-P/AIYH58ubk4Ucmm/2JTaBR+xsS1Come3m0RLF4pu7A=";
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
    version = "0-unstable-2026-06-03";
    pyproject = true;
    __structuredAttrs = true;

    src = fetchFromGitHub {
      owner = "tavily-ai";
      repo = "tavily-cli";
      rev = "798fe2f6bfde66e6383a8d4fdc95e923f2603163";
      hash = "sha256-+9MEUuFgVL/G3BRvke0n25kWiQAm6b8n78AviDRnL0k=";
    };

    build-system = [
      python.pkgs.hatchling
    ];

    dependencies = with python.pkgs; [
      certifi
      click
      httpx
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
