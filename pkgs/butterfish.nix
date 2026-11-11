{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "butterfish";
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "bakks";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-hTMSppr0AuJ7AUjT3gPCXMb4R2x2U4g0vT1ZwbK/wz4=";
  };

  vendorHash = "sha256-b3clnCSWgf1Ro4qWUUmOjwpWEMzeff2O0zZV21efLdg=";
  # Tests fetch the cl100k_base tiktoken encoding from the internet at runtime.
  doCheck = false;
  meta = with lib; {
    description = "A shell with AI superpowers";
    homepage = "https://butterfi.sh/";
    license = licenses.mit;
    maintainers = [];
  };
}
