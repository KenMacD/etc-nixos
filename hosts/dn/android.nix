{ config, lib, pkgs, ... }: {

  programs.adb.enable = true;

  users.users.kenny.extraGroups = [ "adbusers" ];

  environment.systemPackages = with pkgs; [
    abootimg
    android-tools
    apktool
    genymotion
    heimdall
    scrcpy
  ];
}
