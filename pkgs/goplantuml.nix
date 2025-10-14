{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "goplantuml";
  version = "1.6.3";

  src = fetchFromGitHub {
    owner = "jfeliu007";
    repo = "goplantuml";
    rev = "v${version}";
    sha256 = "sha256-+8RvifAYJv6cxIZ9sNKWNVhSNzUotGjjRjGynGqbO6o=";
  };

  vendorHash = null;

  meta = with lib; {
    description = "PlantUML Class Diagram Generator for golang projects";
    homepage = "https://github.com/jfeliu007/goplantuml";
    license = licenses.mit;
  };
}
