{
  lib,
  python,
  fetchFromGitHub,
}:
python.pkgs.buildPythonApplication (finalAttrs: {
  pname = "mcp2cli";
  version = "0-unstable-2026-03-15";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "knowsuchagency";
    repo = "mcp2cli";
    rev = "7967e769d4c0c25a80878b178144683c791d5886";
    hash = "sha256-On3WXdan7xRN0MFURmQ7VUK2qej1ZpX4DA9IX8iGBMY=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "uv_build>=0.9.5,<0.10.0" uv-build
  '';

  build-system = with python.pkgs; [uv-build];

  dependencies = with python.pkgs; [
    httpx
    mcp
    pyyaml
  ];

  optional-dependencies = with python.pkgs; {
    test = [
      pytest
      pytest-asyncio
      tiktoken
    ];
  };

  pythonImportsCheck = [
    "mcp2cli"
  ];

  meta = {
    description = "Turn any MCP, OpenAPI, or GraphQL server into a CLI — at runtime, with zero codegen";
    homepage = "https://github.com/knowsuchagency/mcp2cli";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "mcp2cli";
  };
})
