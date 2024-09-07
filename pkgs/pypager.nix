{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  prompt_toolkit,
  pygments,
  pathspec,
  setuptools,
}:
buildPythonPackage rec {
  pname = "pypager";
  version = "3.0.1";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "prompt-toolkit";
    repo = pname;
    rev = "0255d59a14ffba81c3842ef570c96c8dfee91e8e";
    hash = "sha256-uPpVAI12INKFZDiTQdzQ0dhWCBAGeu0488zZDEV22mU=";
  };

  buildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    prompt_toolkit
    pygments
  ];

  pythonImportsCheck = ["pypager"];

  meta = with lib; {
    description = "Pure Python pager (like \"more\" and \"less\")";
    homepage = "https://github.com/prompt-toolkit/pypager";
    license = licenses.bsd3;
    maintainers = with maintainers; [];
  };
}
