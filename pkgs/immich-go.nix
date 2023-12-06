{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "immich-go";
  version = "0.8.9";

  src = fetchFromGitHub {
    owner = "simulot";
    repo = "immich-go";
    rev = "${version}";
    sha256 = "sha256-aOMVESIEZkjucxB47BayQOujMnR5BGavRiJFKw7pyPI=";
  };

  vendorHash = "sha256-ap+Bj/MBtCmhj2V86iZYB8AYI6sYPfa6b22LLuW9KoE=";

  meta = with lib; {
    description = "An alternative to the immich-CLI command that doesn't depend on nodejs installation. It tries its best for importing google photos takeout archives.";
    homepage = "https://github.com/simulot/immich-go";
  };
}
