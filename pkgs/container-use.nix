{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  git,
}:
# NOTE: git added for tests; Docker may be needed at runtime but is not required for building/tests since problematic tests are skipped
buildGoModule rec {
  pname = "container-use";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "dagger";
    repo = "container-use";
    rev = "v${version}";
    hash = "sha256-YKgS142a9SL1ZEjS+VArxwUzQX961zwlGuHW43AMxQA=";
  };

  vendorHash = "sha256-M7YhEm9Gmjv2gxB2r7AS5JLLThEkvtJfLBrB+cvsN5c=";

  nativeBuildInputs = [installShellFiles git];

  subPackages = [
    "cmd/container-use"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.commit=${src.rev}"
    "-X=main.date=1970-01-01T00:00:00Z"
  ];

  checkFlags = [
    "-skip"
    "TestSharedRepositoryContention|TestRepositoryContention|TestSingleTenantRepositoryContention"
  ];

  postInstall = ''
    installShellCompletion --cmd container-use \
    --bash <($out/bin/container-use completion bash) \
    --fish <($out/bin/container-use completion fish) \
    --zsh <($out/bin/container-use completion zsh)
    # Create cu symlink for backward compatibility
    ln -sf $out/bin/container-use $out/bin/cu
    # Install cu completions for backward compatibility
    installShellCompletion --cmd cu \
    --bash <($out/bin/cu completion bash) \
    --fish <($out/bin/cu completion fish) \
    --zsh <($out/bin/cu completion zsh)
  '';

  meta = {
    description = "Development environments for coding agents. Enable multiple agents to work safely and independently with your preferred stack";
    homepage = "https://github.com/dagger/container-use";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [];
    mainProgram = "container-use";
  };
}
