{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
}:
stdenv.mkDerivation rec {
  pname = "cclimits";
  version = "v1.2.9";

  src = fetchFromGitHub {
    owner = "cruzanstx";
    repo = "cclimits";
    rev = version;
    hash = "sha256-jBDYDWt4bB4OFGbxbLBtsKywflqqOBEQ/4eLm6XZhD8=";
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
