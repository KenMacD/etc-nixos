{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage rec {
  pname = "acpx";
  version = "0.15.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/acpx/-/acpx-${version}.tgz";
    hash = "sha256-kEr3okZgj4loE/jsoMuveplVW4I0s+BdIjV/LVDVg1c=";
  };

  sourceRoot = "package";
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-WHqIA5p4V33tb86Kb8LfrMEJKUkx4lvF7Rh3YAWdKKY=";
  npmDepsFetcherVersion = 2;
  dontNpmBuild = true;

  meta = {
    description = "Headless CLI client for the Agent Client Protocol";
    homepage = "https://github.com/openclaw/acpx";
    license = lib.licenses.mit;
    mainProgram = "acpx";
  };
}
