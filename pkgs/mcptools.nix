{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcptools";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "f";
    repo = "mcptools";
    rev = "v${version}";
    hash = "sha256-UFK57MzsxoLdtdFhhQ+x57LomyOBijxyHkOCgj6NuJI=";
  };

  vendorHash = "sha256-tHMBwYZUrcohUEpIXgbhSCkxRi+/GxnPtEX4Uj5rwjo=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${version}"
    # "-X=main.TemplatesPath=${templatesPath}"
  ];

  meta = {
    description = "A command-line interface for interacting with MCP (Model Context Protocol) servers using both stdio and HTTP transport";
    homepage = "https://github.com/f/mcptools";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "mcptools";
  };
}
