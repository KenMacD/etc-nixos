{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "butterfish";
  version = "0.3.10";

  src = fetchFromGitHub {
    owner = "bakks";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-fHqCD/d3xpJBB5a2nRcSv5t/jZRPtCnPANAslwjBSEo=";
  };

  vendorHash = "sha256-b3clnCSWgf1Ro4qWUUmOjwpWEMzeff2O0zZV21efLdg=";
  meta = with lib; {
    description = "A shell with AI superpowers";
    homepage = "https://butterfi.sh/";
    license = licenses.mit;
    maintainers = [];
  };
}
