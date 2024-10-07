{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}: {
  environment.systemPackages = with pkgs; [
    (azure-cli.withExtensions (with pkgs.azure-cli-extensions; [graphservices]))
    checkov # Static code analysis tool for infrastructure-as-code
    drawio
    freerdp3
    gh-copilot
    (granted.override {withFish = true;})
    jira-cli-go
    postman
    slirp4netns
    terraformer
    terragrunt

    # K8 clients
    k9s
    kdash
    seabird
  ];
}
