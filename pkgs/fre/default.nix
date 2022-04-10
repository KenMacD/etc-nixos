{ lib, stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "fre";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "camdencheek";
    repo = pname;
    rev = version;
    sha256 = "0j7cdvdc1007gs1kixk36y2zlgrkixqiaqvnkwd0pk56r4pbwvcw";
  };

  cargoSha256 = "0zb1x1qm4pw7hmkljsnrd233qzmk24c5v6x3q2dsfc5rp9xicjyb";

  meta = with lib; {
    description = "Command line frecency tracking";
    homepage = "https://github.com/camdencheek/fre/";
    license = licenses.mit;
    maintainers = [ ];
  };
}
