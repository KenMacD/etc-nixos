{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  ollama,
}:
buildPythonPackage rec {
  pname = "llm-ollama";
  version = "0.5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "taketwo";
    repo = "llm-ollama";
    rev = version;
    sha256 = "sha256-QxmFgiy+Z5MNtnf2nvGndZk2MMuMhkOfofUsxCoh7J0=";
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
