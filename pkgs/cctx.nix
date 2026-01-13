{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
}:
rustPlatform.buildRustPackage rec {
  pname = "cctx";
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "nwiizo";
    repo = "cctx";
    rev = "v${version}";
    hash = "sha256-Al+k0UQdUQg4i/j+EkebKcIbtS8adBWSzplHk0imLxU=";
  };

  cargoHash = "sha256-tVRwPxAvcNJDtAmU+NZ1bBvB04wtrRLElchoY4jgxMA=";

  nativeBuildInputs = [installShellFiles];

  # completions don't work because they use current contexts in the generation

  meta = {
    description = "Claude Code context manager for switching between multiple settings.json configurations";
    homepage = "https://github.com/nwiizo/cctx";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "cctx";
  };
}
