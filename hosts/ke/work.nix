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

    (granted.override {withFish = true;})
  ];
}
