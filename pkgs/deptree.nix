{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "deptree";
  version = "a8afffff4b0610bb7a480a086cc27c3dde54afb7";

  src = fetchFromGitHub {
    owner = "vc60er";
    repo = "deptree";
    rev = "${version}";
    sha256 = "sha256-xjM4VnWoqea3KppsAy1MkGgELT94fXSfuw6/ASxDdHE=";
  };

  vendorHash = "sha256-k2TXOedsF4dDUqltq9CGLdMd303I7AHRvODA88U3xw0=";

  #excludedPackages = ["gen_cmd_docs" "verify_boilerplate"];

  meta = with lib; {
    description = "show golang dependence like tree";
    homepage = "https://github.com/vc60er/deptree";
  };
}
