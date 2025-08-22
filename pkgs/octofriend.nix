{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
}:
buildNpmPackage rec {
  pname = "octofriend";
  version = "0.0.29";

  src = fetchFromGitHub {
    owner = "synthetic-lab";
    repo = "octofriend";
    rev = "32e066d2f322321146f6a9fd86b853eebd688ede";
    hash = "sha256-iVa/EJzz1bzvtnWEz1cPnhkVqRjwsJw2NOkbJiehVns=";
  };

  inherit nodejs;

  npmDepsHash = "sha256-PIZ1VnbeUZoAJREe8HUxy0iKcObbm4PMjb5jmklIh2M=";

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
