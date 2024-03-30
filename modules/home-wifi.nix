{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home-wifi;
in {
  options.home-wifi = {
    enable = mkEnableOption "Enable home wifi network setup";
  };

  config = mkIf cfg.enable {
    systemd.network.networks =
      foldl'
      (acc: interface:
        {
          "30-homewifi-${interface}" = {
            matchConfig = {
              Name = interface;
              SSID = "MacDermid";
            };
            networkConfig =
              {
                MulticastDNS = true;
              }
              // (getAttr "40-${interface}" config.systemd.network.networks).networkConfig;
            dhcpV4Config = {
              UseDomains = true;
            };
          };
        }
        // acc)
      {}
      config.networking.wireless.interfaces;
  };
}
