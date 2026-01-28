{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "octofriend";
  version = "0.0.52";

  src = fetchFromGitHub {
    owner = "synthetic-lab";
    repo = "octofriend";
    rev = "e5540baa1a940d27400416491e17b42987309351";
    hash = "sha256-P9eJpIuw8pQpHC/AQTqisiCpbsxRoH2/ER/E5PbnsGQ=";
  };

  npmDepsHash = "sha256-FWrDtk8mgpeTSUFe+Ektc5Nbko3OYRzs/yrhLmsfhRE=";

  nodejs = nodejs_22;

  installPhase = ''
    runHook preInstall

    # Copy the built files
    mkdir -p $out/lib/node_modules/octofriend
    cp -r dist $out/lib/node_modules/octofriend/
    cp -r drizzle $out/lib/node_modules/octofriend/
    cp -r node_modules $out/lib/node_modules/octofriend/
    cp package.json $out/lib/node_modules/octofriend/
    cp drizzle.config.ts $out/lib/node_modules/octofriend/
    cp CHANGELOG.md $out/lib/node_modules/octofriend/
    cp IN-APP-UPDATES.txt $out/lib/node_modules/octofriend/
    cp tsconfig.json $out/lib/node_modules/octofriend/

    # Create bin directory and symlink
    mkdir -p $out/bin
    cat > $out/bin/octofriend << EOF
    #!/bin/sh
    exec ${nodejs}/bin/node $out/lib/node_modules/octofriend/dist/source/cli.js "\$@"
    EOF
    chmod +x $out/bin/octofriend

    # Also create the shorter alias
    ln -s $out/bin/octofriend $out/bin/octo

    runHook postInstall
  '';

  meta = with lib; {
    description = "A small, helpful, cephalopod-flavored coding assistant";
    homepage = "https://github.com/synthetic-lab/octofriend";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "octofriend";
  };
}
