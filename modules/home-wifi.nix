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
    systemd.network.networks."30-homewifi" = {
      matchConfig = {
        Name = "wlp0s20f3";
        BSSID = "3c:cd:57:98:cd:bb";
        SSID = "MacDermid";
      };
      networkConfig = {
        MulticastDNS = true;
      } // config.systemd.network.networks."40-wlp0s20f3".networkConfig;
      dhcpV4Config = {
        UseDomains = true;
      };
    };
  };
}
