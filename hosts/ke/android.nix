{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.kenny.extraGroups = ["adbusers"];

  environment.systemPackages = with pkgs; [
    abootimg
    android-tools
    apktool
    genymotion
    scrcpy
  ];
}
