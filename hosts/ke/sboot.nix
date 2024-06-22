{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
  environment.systemPackages = with pkgs; [
    sbctl
  ];
}
