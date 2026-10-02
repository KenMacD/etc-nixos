{
  lib,
  stdenv,
  makeWrapper,
  fetchFromGitHub,
  python3,
}:
stdenv.mkDerivation rec {
  pname = "cclimits";
  version = "1.7.0-unstable-2026-09-29";

  src = fetchFromGitHub {
    owner = "cruzanstx";
    repo = "cclimits";
    rev = "830848bf57c1e17a7baad0d10f6a4cb962166ba3";
    hash = "sha256-aNsyS/8jl1UeHUD9gnp7Eaj36nzRul5FaVcMlmAs0p4=";
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
