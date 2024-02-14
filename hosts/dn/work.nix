{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
{

  environment.systemPackages = with pkgs; [
    drawio
    jira-cli-go

    freerdp3

    (granted-update.override {withFish = true;})
  ];
}
