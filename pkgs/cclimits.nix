{
  lib,
  stdenv,
  makeWrapper,
  fetchFromGitHub,
  python3,
}:
stdenv.mkDerivation rec {
  pname = "cclimits";
  version = "1.7.2";

  src = fetchFromGitHub {
    owner = "cruzanstx";
    repo = "cclimits";
    rev = "v${version}";
    hash = "sha256-kiFOL+2vue1rAP25ONKgxx7qFohQ3z4fRZqqZXa0uqc=";
  };

  nativeBuildInputs = [makeWrapper];
  buildInputs = [python3];

  installPhase = ''
    runHook preInstall
    # Entry point imports sibling modules (opencode_zen, opencode_web,
    # codex_native), so install the whole lib dir and run from there.
    for f in lib/*.py; do
      install -Dm644 "$f" "$out/lib/cclimits/$(basename "$f")"
    done
    chmod +x "$out/lib/cclimits/cclimits.py"
    mkdir -p "$out/bin"
    makeWrapper "${python3}/bin/python3" "$out/bin/cclimits" \
      --add-flags "$out/lib/cclimits/cclimits.py"
    runHook postInstall
  '';

  meta = {
    description = "Manage Cloud Control limits";
    homepage = "https://github.com/cruzanstx/cclimits";
    license = lib.licenses.mit;
    mainProgram = "cclimits";
  };
}
