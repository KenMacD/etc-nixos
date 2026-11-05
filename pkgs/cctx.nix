{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
}:
rustPlatform.buildRustPackage rec {
  pname = "cctx";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "nwiizo";
    repo = "cctx";
    rev = "v${version}";
    hash = "sha256-pk8OMJYSeXegvUq+aV61yTmiVux5F8R+/ETpY6mbn3g=";
  };

  cargoHash = "sha256-lvpwpJ53HV2Akx1fzK06b+Rq7h4tcq0VOM2KKnxyMPA=";

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
