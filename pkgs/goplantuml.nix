{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "goplantuml";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "jfeliu007";
    repo = "goplantuml";
    rev = "v${version}";
    sha256 = "sha256-OnCAqws27e7WsXKmw0clH9Qek+6LNeu2UGD9sKaV4+I=";
  };

  vendorHash = null;

  meta = with lib; {
    description = "PlantUML Class Diagram Generator for golang projects";
    homepage = "https://github.com/jfeliu007/goplantuml";
    license = licenses.mit;
  };
}
