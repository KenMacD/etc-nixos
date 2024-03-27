{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.network.enable = true;

  networking.usePredictableInterfaceNames = true;
  networking.wireless.interfaces = [
    "wlp4s0"
  ];

  networking.useHostResolvConf = lib.mkDefault (!config.systemd.network.enable);
  networking.resolvconf.dnsSingleRequest = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.enp3s0.useDHCP = true;
}
