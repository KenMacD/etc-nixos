{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  llm,
}: let
  version = "0.1.6";
in
  buildPythonPackage {
    pname = "llm-deepseek";
    inherit version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "abrasumente233";
      repo = "llm-deepseek";
      rev = version;
      hash = "sha256-yrNvIGnU9Q/0H786DsM0wGEwfxZYIk8IXhqC4mWaQAA=";
    };

    build-system = [
      setuptools
      llm
    ];

    pythonImportsCheck = [
      "llm_deepseek"
    ];

    meta = {
      description = "Access deepseek.com models via API";
      homepage = "https://github.com/abrasumente233/llm-deepseek";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [];
      mainProgram = "llm-deepseek";
    };
  }
