{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  anthropic,
}:
buildPythonPackage rec {
  pname = "llm-claude-3";
  version = "0.4.1";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-claude-3";
    rev = version;
    sha256 = "sha256-FedR4g+B0wfzSJYC+3x9cJljV870XSU9hhRec7xaC8w=";
  };

  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = [
    anthropic
  ];

  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "LLM access to Claude 3 by Anthropic";
    homepage = "https://github.com/simonw/llm-claude-3";
    license = licenses.asl20;
  };
}
