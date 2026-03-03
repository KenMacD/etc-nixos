{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "alph-cli";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "Aqualia";
    repo = "Alph";
    rev = "v${version}";
    hash = "sha256-F+w8UOV4UGSXr3sgaJ0GzDnHRu7v4gq4u65AliN6iXo=";
  };

  npmDepsHash = "sha256-5/Z0cfJ3y5l94ai/xMcynLlyfIbiT/HAysw37smnrws=";

  doCheck = false;

  meta = with lib; {
    description = "Universal MCP Server Configuration Manager for AI agents";
    homepage = "https://github.com/Aqualia/Alph";
    license = licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "alph";
  };
}
