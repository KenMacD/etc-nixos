{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "grev";
  version = "0.4.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "aurorainfra";
    repo = "grev";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BMRPmp71jpk/beWOk+AjwTenZw/QiavbDb/ODg3KNDI=";
  };

  vendorHash = null;

  # eval/ is an opt-in, tag-gated (`//go:build eval`) live-API benchmark
  # harness with no buildable files; exclude it from the build/test loops.
  excludedPackages = ["eval"];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/aurorainfra/grev/internal/cli.Version=${finalAttrs.version}"
  ];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Thinking coreutils";
    homepage = "https://github.com/aurorainfra/grev";
    changelog = "https://github.com/aurorainfra/grev/releases/tag/${finalAttrs.src.tag}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [];
    mainProgram = "grev";
  };
})
