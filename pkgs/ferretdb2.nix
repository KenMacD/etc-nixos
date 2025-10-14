{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ferretdb";
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "FerretDB";
    repo = "FerretDB";
    rev = "v${version}";
    sha256 = "sha256-zQT8ALD5qFxrss8h/UO705Wl8uEXn3srTULcAO4YOSc=";
  };

  postPatch = ''
    echo v${version} > build/version/version.txt
    echo nixpkgs     > build/version/package.txt

    # Fix for setGOMAXPROCS undefined error
    # In newer Go versions, runtime.GOMAXPROCS is handled automatically
    # Remove when version above 2.5.0
    # (See https://github.com/FerretDB/FerretDB/pull/5508/)
    sed -i '367s/.*/\/\/ Removed setGOMAXPROCS call due to Go version incompatibility/' cmd/ferretdb/main.go
  '';

  vendorHash = "sha256-4AlbcJOvYvSvT5DoL3+05luBQCatmsFYyd08RJSs7Wg=";

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
