{
  python3Packages,
  fetchFromGitHub,
}:
# https://github.com/vdesjardins/nix-config/blob/cab7b9ce80b4488cc643506f2d4738a58686eed0/packages/mcp-server-tree-sitter.nix#L10
python3Packages.buildPythonApplication rec {
  pname = "mcp-server-tree-sitter";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "wrale";
    repo = "mcp-server-tree-sitter";
    rev = "v${version}";
    hash = "sha256-GF7UxhcDUOGHaxqKZ5GPAHfrCBNEi6P6FCFwa52Gjsw=";
  };

  dependencies = with python3Packages; [
    mcp
    pydantic
    pygments
    pyyaml
    types-pyyaml
    tree-sitter
    tree-sitter-language-pack
  ];

  build-system = [python3Packages.hatchling];
  pyproject = true;

  meta = {
    description = "MCP Server for Tree-sitter";
    homepage = "https://github.com/wrale/mcp-server-tree-sitter";
    mainProgram = "mcp-server-tree-sitter";
  };
}
