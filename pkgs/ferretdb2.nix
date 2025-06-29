{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ferretdb";
  version = "2.3.1";

  src = fetchFromGitHub {
    owner = "FerretDB";
    repo = "FerretDB";
    rev = "v${version}";
    sha256 = "sha256-kj2w3s8+KrhDCO2IWH0xO+3lXGtjMWHGj/hoY8V/At0=";
  };

  postPatch = ''
    echo v${version} > build/version/version.txt
    echo nixpkgs     > build/version/package.txt
  '';

  vendorHash = "sha256-m8+lJ14rgp3MFJPnLkC44EEC/CSbzI06yxRDFUvoWRo=";

  env.CGO_ENABLED = 0;

  subPackages = ["cmd/ferretdb"];

  tags = ["ferretdb_tigris"];

  # tests in cmd/ferretdb are not production relevant
  doCheck = false;

  # the binary panics if something required wasn't set during compilation
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/ferretdb --version | grep ${version}
  '';

  meta = with lib; {
    description = "A truly Open Source MongoDB alternative";
    homepage = "https://www.ferretdb.io/";
    license = licenses.asl20;
    maintainers = with maintainers; [dit7ya noisersup julienmalka];
  };
}
