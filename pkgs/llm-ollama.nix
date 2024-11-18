{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  ollama,
}:
buildPythonPackage rec {
  pname = "llm-ollama";
  version = "0.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "taketwo";
    repo = "llm-ollama";
    rev = version;
    hash = "sha256-DYhhCsvCMQnxxaKVinkz5C3qZPiD+rVpwHyEQnWuh4s=";
  };

  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = [
    ollama
  ];

  # We can't add llm as a propagatedBuildInput as it creates a
  # circular dependency.
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "LLM plugin providing access to models running on local Ollama server.";
    homepage = "https://github.com/taketwo/llm-ollama";
    license = licenses.mit;
  };
}
