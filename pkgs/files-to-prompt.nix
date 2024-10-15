{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  setuptools,
  click,
}: let
  pname = "files-to-prompt";
  version = "0.3";
in
  buildPythonApplication {
    inherit pname version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "simonw";
      repo = pname;
      rev = version;
      hash = "sha256-CIg5W8CztrUAKL8czCn8cc7WMKZMx5EdClbR0+7C1pU=";
    };

    build-system = [setuptools];

    propagatedBuildInputs = [click];

    pythonImportsCheck = ["files_to_prompt"];

    meta = with lib; {
      description = "Concatenate a directory full of files into a single prompt for use with LLMs";
      homepage = "https://github.com/simonw/files-to-prompt";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [];
    };
  }
