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
    jira-cli-go

    freerdp3

    (granted.override {withFish = true;})

    # K8 clients
    k9s
    kdash
    seabird

    postman
    gh-copilot
  ];
}
