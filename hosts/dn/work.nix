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

    (granted-update.override {withFish = true;})
  ];
}
