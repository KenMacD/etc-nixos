{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "butterfish";
  version = "0.2.15";

  src = fetchFromGitHub {
    owner = "bakks";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-FvXmC88qU1/lY4Az5ReUphuoaYk13I6sKgDZSL+JeMo=";
  };

  vendorHash = "sha256-HZNCcNrIl+POna42WaBzuj/OUb+hXW1E9htJG3nOhbI=";
  meta = with lib; {
    description = "A shell with AI superpowers";
    homepage = "https://butterfi.sh/";
    license = licenses.mit;
    maintainers = [];
  };
}
