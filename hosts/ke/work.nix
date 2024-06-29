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
  ];
}
