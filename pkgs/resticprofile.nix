{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "resticprofile";
  version = "0.26.0";

  src = fetchFromGitHub {
    owner = "creativeprojects";
    repo = "resticprofile";
    rev = "v${version}";
    sha256 = "sha256-y2rBUivs5yxlD/0uFwXW/Zc+o3foTmydwtEkyiuJwyw=";
  };

  vendorHash = "sha256-Qi7uhMXaWqI4NmYi+XTR15SyiUGhRiXPZmVud6aTM4s=";
  tags = ["no_self_update"];
  doCheck = false;
  subPackages = ["."];
}
