{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "go-mod-upgrade";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "oligot";
    repo = "go-mod-upgrade";
    rev = "v${version}";
    sha256 = "sha256-+C0IMb7MU1fq/P0/tTUNmzznZ1q5M69491pO5yBZlVs=";
  };

  vendorHash = "sha256-8rbRxtOiKmnf68kjsUCXaZf+MHI1n5aXa91Aneq9SKo=";
}
