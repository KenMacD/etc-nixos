{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
# TODO: add git/docker to dependencies (see install script)?
buildGoModule rec {
  pname = "container-use";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "dagger";
    repo = "container-use";
    rev = "v${version}";
    hash = "sha256-qhE36b8sNOz6i5E4266tgbEymm9F6eowq3T7MolYiiE=";
  };

  vendorHash = "sha256-XzxcnP2BGW0cbMh/0r4r606qrFVEq4ZXU5vXySKUQqU=";

  subPackages = [
    "cmd/cu"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.commit=${src.rev}"
    "-X=main.date=1970-01-01T00:00:00Z"
  ];

  meta = {
    description = "Development environments for coding agents. Enable multiple agents to work safely and independently with your preferred stack";
    homepage = "https://github.com/dagger/container-use";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [];
    mainProgram = "container-use";
  };
}
