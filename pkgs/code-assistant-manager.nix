{
  lib,
  python,
  fetchFromGitHub,
}:
python.pkgs.buildPythonApplication rec {
  pname = "code-assistant-manager";
  version = "1.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Chat2AnyLLM";
    repo = "code-assistant-manager";
    rev = version;
    hash = "sha256-0DRi2UuQrE7X8M31kxH6BMiKpsAjjaRhtZvPV5RfPD8=";
  };

  build-system = with python.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python.pkgs; [
    click
    httpx
    pydantic
    python-dotenv
    pyyaml
    requests
    rich
    setuptools-scm
    tabulate
    tomli
    tomli-w
    typer
    typing-extensions
  ];

  optional-dependencies = with python.pkgs; {
    dev = [
      bandit
      black
      flake8
      flake8-bugbear
      flake8-comprehensions
      flake8-simplify
      interrogate
      isort
      mypy
      pexpect
      pre-commit
      pytest
      pytest-asyncio
      pytest-cov
      types-pyyaml
      types-requests
    ];
  };

  pythonImportsCheck = [
    "code_assistant_manager"
  ];

  meta = {
    description = "Code-assitant-manager allows you to manage the code assistants like claude code, codex, gemini on a single interface";
    homepage = "https://github.com/Chat2AnyLLM/code-assistant-manager";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "code-assistant-manager";
  };
}
