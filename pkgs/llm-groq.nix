{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  llm,
  groq,
}: let
  version = "0.8";
in
  buildPythonPackage {
    pname = "llm-groq";
    inherit version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "angerman";
      repo = "llm-groq";
      rev = "v${version}";
      hash = "sha256-sZ5d9w43NvypaPrebwZ5BLgRaCHAhd7gBU6uHEdUaF4=";
    };

    build-system = [
      setuptools
      llm
    ];

    dependencies = [
      groq
    ];
    ythonImportsCheck = ["llm_anthropic"];

    pythonImportsCheck = [
      "llm_groq"
    ];

    meta = {
      description = "LLM plugin for models hosted on Groq";
      homepage = "https://github.com/angerman/llm-groq";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [];
    };
  }
