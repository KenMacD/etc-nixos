{
  fetchPypi,
  lib,
  python3Packages,
}:
# From https://github.com/nix-community/nur-combined/blob/master/repos/javimerino/pkgs/llm-ollama/default.nix
python3Packages.buildPythonApplication rec {
  pname = "llm-ollama";
  version = "0.4.3";
  pyproject = true;
  src = fetchPypi {
    pname = "llm_ollama";
    inherit version;
    hash = "sha256-fYyMeSAmFKMJZFiDQlQ1tHlVTkyGPCDmt0l43WmkjUc=";
  };

  nativeBuildInputs = [
    python3Packages.setuptools
  ];
  propagatedBuildInputs = [
    python3Packages.ollama
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
