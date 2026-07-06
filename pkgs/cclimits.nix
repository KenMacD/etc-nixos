{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
}:
stdenv.mkDerivation rec {
  pname = "cclimits";
  version = "v1.2.12";

  src = fetchFromGitHub {
    owner = "cruzanstx";
    repo = "cclimits";
    rev = version;
    hash = "sha256-9svkDDgXkI/Ie2pGMFqio1sIi+QOBgY0sdMb5CaBtU0=";
  };

  buildInputs = [python3];

  installPhase = ''
    runHook preInstall
    install -Dm755 lib/cclimits.py $out/bin/cclimits
    runHook postInstall
  '';

  meta = {
    description = "Manage Cloud Control limits";
    homepage = "https://github.com/cruzanstx/cclimits";
    license = lib.licenses.mit;
    mainProgram = "cclimits";
  };
}
