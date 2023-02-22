{ config, pkgs, lib, ... }:

{
  networking.usePredictableInterfaceNames = true;
  networking.wireless.interfaces = [
    "wlp0s20f3"
  ];

  networking.useHostResolvConf = lib.mkDefault (!config.systemd.network.enable);
  networking.resolvconf.dnsSingleRequest = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    networks = {
    };
  };
}
