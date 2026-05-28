{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.network.enable = true;

  networking.usePredictableInterfaceNames = true;

  networking.useHostResolvConf = lib.mkDefault (!config.systemd.network.enable);
  networking.resolvconf.dnsSingleRequest = true;
}
