{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "packnplay";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "obra";
    repo = "packnplay";
    rev = "v${version}";
    hash = "sha256-sr5aiYWcH8TpBgOIwn4HgvOL7nqjzpKydRWgY8Q0GYE=";
  };

  vendorHash = "sha256-kF5lC0UgaTo2z8hgoorFp44glDRxEJ/9vdEmKlVtk2k=";

  checkFlags = let
    # System-dependent tests that fail in Nix build environment
    skippedTests = [
      # Tries to detect container runtimes (Docker, Podman) not available in build env
      "TestDetectAvailableRuntimes"
      # Attempts to create directories in home path that doesn't exist in build env
      "TestVersionTrackingFileLocation"
      # Tries to detect Docker in PATH which is not available in build environment
      "TestDetectDockerCLI"
    ];
  in ["-skip=^${lib.concatStringsSep "$|^" skippedTests}$"];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/obra/packnplay/cmd.version=${version}"
    "-X=github.com/obra/packnplay/cmd.commit=${src.rev}"
    "-X=github.com/obra/packnplay/cmd.date=1970-01-01T00:00:00Z"
  ];

  meta = {
    description = "Sandboxed execution of commands in Docker containers with automated worktree and dev container management";
    homepage = "https://github.com/obra/packnplay";
    changelog = "https://github.com/obra/packnplay/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "packnplay";
  };
}
