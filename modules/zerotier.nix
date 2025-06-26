{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.zerotier-home;
  domain = "zero.macdermid.ca";
  network = "3efa5cb78a1548d5";
  dnsServers = [
    # TODO: sync from ZT console
    "fd3e:fa5c:b78a:1548:d599:93db:5a5b:1290" # r1pro
  ];
  ztInterface = "ztrfyet727";
in {
  options.services.zerotier-home = {
    enable = mkEnableOption "Zerotier network";
  };

  config = mkIf cfg.enable {
    # TODO: when systemd 258 see if delegates will work
    # https://github.com/systemd/systemd/pull/34368
    networking.hosts = {
      "fd3e:fa5c:b78a:1548:d599:9320:cd20:ef74" = ["edgemax" "edgemax.zero.macdermid.ca"];
      "fd3e:fa5c:b78a:1548:d599:93bd:36c5:7846" = ["ke" "ke.zero.macdermid.ca"];
      "fd3e:fa5c:b78a:1548:d599:93db:5a5b:1290" = ["r1pro" "r1pro.zero.macdermid.ca"];
      "fd3e:fa5c:b78a:1548:d599:93e6:e04f:ec84" = ["yoga" "yoga.zero.macdermid.ca"];
    };

    services.zerotierone = {
      enable = true;
      joinNetworks = [network];
      localConf = {
        settings = {
          softwareUpdate = "disable";
        };
      };
    };

    systemd.services.zerotierone.serviceConfig = {
      KillMode = lib.mkForce "control-group";
      TimeoutStopFailureMode = "kill";
    };

    systemd.network.networks."51-zerotier-dns" = {
      matchConfig = {
        Name = ztInterface;
      };
      # Options from https://github.com/zerotier/zerotier-systemd-manager/blob/main/template.network
      networkConfig = {
        ConfigureWithoutCarrier = true;
        DHCP = false;
        DNS = dnsServers;
        DNSDefaultRoute = false;
        Domains = domain;
        KeepConfiguration = "static";
      };
    };
  };
}
