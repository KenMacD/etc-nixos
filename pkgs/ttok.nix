{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  setuptools,
  click,
  tiktoken,
}: let
  version = "0.3";
in
  buildPythonApplication {
    pname = "llm-ttok";
    inherit version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "simonw";
      repo = "ttok";
      rev = version;
      hash = "sha256-I6EPE6GDAiDM+FbxYzRW4Pml0wDA2wNP1y3pD3dg7Gg=";
    };

    build-system = [setuptools];

    propagatedBuildInputs = [
      click
      tiktoken
    ];

    pythonImportsCheck = ["ttok"];

    meta = with lib; {
      description = "Count and truncate text based on tokens";
      homepage = "https://github.com/simonw/ttok";
      license = licenses.asl20;
      maintainers = [];
    };
  }
