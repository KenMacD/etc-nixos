{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  anthropic,
}:
buildPythonPackage rec {
  pname = "llm-claude-3";
  version = "0.9";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-claude-3";
    rev = version;
    hash = "sha256-tN4rWfXVDkcfyTTvDsvwvTlYzkPeZE7fL5ufTyhL+Wc=";
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
