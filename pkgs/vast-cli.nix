{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  nix-update-script,
  # build
  poetry-core,
  poetry-dynamic-versioning,
  # runtime
  aiodns,
  aiohttp,
  anyio,
  argcomplete,
  borb,
  cryptography,
  curlify,
  pillow,
  psutil,
  pycares,
  pycryptodome,
  pyparsing,
  python-dateutil,
  requests,
  rich,
  typing-extensions,
  urllib3,
  xdg,
}:
buildPythonApplication (finalAttrs: {
  pname = "vast-cli";
  version = "1.5.2";
  pyproject = true;
  __structuredAttrs = true;

  # Upstream pyproject over-pins deps that nixpkgs/unstable (py3.14) exceeds:
  #   borb~=2.1.25  (nixpkgs: 3.x), pycares==4.11.0 (nixpkgs: 5.x), pillow==12.2.0 (nixpkgs: 12.3).
  # borb is only referenced by the deprecated vast_pdf invoice helper
  # (guarded by try/except ImportError), so accept the drift and skip the
  # strict wheel runtime-deps check.
  dontCheckRuntimeDeps = true;

  src = fetchFromGitHub {
    owner = "vast-ai";
    repo = "vast-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7kcx0JUVkscOTtii8pP+5JgGjCwJ/LLr6imlveniLPk=";
  };

  build-system = [
    poetry-core
    poetry-dynamic-versioning
  ];

  dependencies = [
    aiodns
    aiohttp
    anyio
    argcomplete
    borb
    cryptography
    curlify
    pillow
    psutil
    pycares
    pycryptodome
    pyparsing
    python-dateutil
    requests
    rich
    typing-extensions
    urllib3
    xdg
  ];

  pythonImportsCheck = [
    "vastai"
  ];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Vast.ai python and cli api client";
    homepage = "https://github.com/vast-ai/vast-cli";
    changelog = "https://github.com/vast-ai/vast-cli/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "vast-cli";
  };
})
