{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  boost,
  souffle,
  z3,
}:
stdenv.mkDerivation rec {
  pname = "souffle-addon";
  version = "1439614";

  src = fetchFromGitHub {
    owner = "plast-lab";
    repo = "souffle-addon";
    rev = "1439614618b4a5b65925bd0d04c2bf371adb4b48";
    hash = "sha256-5GrWSEqRu731uwazCywhN17Ko/d8QVZ+HH07YpYHIgE=";
  };

  patches = [
    ./test-reorder-fix.patch
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    boost
    souffle
    z3
  ];

  # Makefile does: ln -sf libsoufflenum.so libfunctors.so
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp libfunctors.so $out/lib
    cp libsoufflenum.so $out/lib
  '';

  meta = {
    description = "A simple add-on dynamic library for more complex arithmetic operations in Souffle-Datalog";
    homepage = "https://github.com/plast-lab/souffle-addon";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [];
    mainProgram = "souffle-addon";
    platforms = lib.platforms.all;
  };
}
