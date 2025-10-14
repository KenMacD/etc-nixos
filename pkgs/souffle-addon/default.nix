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
  version = "992145c";

  src = fetchFromGitHub {
    owner = "plast-lab";
    repo = "souffle-addon";
    rev = "992145cd85da891dd28322cd16460f5e23e6dee4";
    hash = "sha256-XJTecDYcKBnEWG8ZRetBADS0f/m5pa8gne9cTjhm2Z4=";
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
