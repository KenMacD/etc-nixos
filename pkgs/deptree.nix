{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "deptree";
  version = "8984b09e9e5b9adf8ba5eac818ea10c51d2244f4";

  src = fetchFromGitHub {
    owner = "vc60er";
    repo = "deptree";
    rev = "${version}";
    sha256 = "sha256-FXleBbuC89nUkNij1TqIcQlQo44Uz6KKxt/URgDStTw=";
  };

  vendorHash = "sha256-k2TXOedsF4dDUqltq9CGLdMd303I7AHRvODA88U3xw0=";

  #excludedPackages = ["gen_cmd_docs" "verify_boilerplate"];

  meta = with lib; {
    description = "show golang dependence like tree";
    homepage = "https://github.com/vc60er/deptree";
  };
}
