{
  lib,
  python,
  fetchFromGitHub,
}:
python.pkgs.buildPythonApplication (finalAttrs: {
  pname = "mcp2cli";
  version = "0-unstable-2026-11-05";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "knowsuchagency";
    repo = "mcp2cli";
    rev = "cf81e493b2ace3d274641f666629eebd3f736b3b";
    hash = "sha256-bIiHBiv8s3BCfWoxBCPh0AML1lWMGhUXXBEJDBMyB94=";
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
