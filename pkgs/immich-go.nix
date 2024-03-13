{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "immich-go";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "simulot";
    repo = "immich-go";
    rev = "${version}";
    sha256 = "sha256-ZY5sfWlrpUpteoCa7bP2A+GUnsTMaXJPSBLqgSANxIQ=";
  };

  vendorHash = "sha256-02Zbht2YM/YGeJrgyblMI0b3rplhOUNZMZ82M4mZ+8o=";

  meta = with lib; {
    description = "An alternative to the immich-CLI command that doesn't depend on nodejs installation. It tries its best for importing google photos takeout archives.";
    homepage = "https://github.com/simulot/immich-go";
  };
}
