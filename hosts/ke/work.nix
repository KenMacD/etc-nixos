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
    drawio
    freerdp3
    gh-copilot
    (granted.override {withFish = true;})
    jira-cli-go
    postman
    slirp4netns

    # K8 clients
    k9s
    kdash
    seabird
  ];
}
