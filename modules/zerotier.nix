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
    "fd3e:fa5c:b78a:1548:d599:9336:cc44:4d02" # dn
    "fd3e:fa5c:b78a:1548:d599:93db:5a5b:1290" # r1pro
  ];
  ztInterface = "ztrfyet727";
in {
  options.services.zerotier-home = {
    enable = mkEnableOption "Zerotier network";

    zeronsd = {
      enable = mkEnableOption "Zerotier NS daemon";
      package = mkOption {
        type = types.package;
        description = mkDoc "ZeroNSD Package";
        default = pkgs.callPackage ../pkgs/zeronsd {};
      };
    };
  };

  config = mkIf cfg.enable {
    # Must contain ZEROTIER_CENTRAL_TOKEN
    sops.secrets.zeronsd = {
      sopsFile = ./zerotier.secrets.yaml;
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

    systemd.services.zeronsd = mkIf cfg.zeronsd.enable {
      description = "zeronsd";

      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "zerotierone.service"];
      requires = ["network-online.target" "zerotierone.service"];

      serviceConfig = {
        Type = "simple";
        EnvironmentFile = config.sops.secrets.zeronsd.path;

        # Probably a better way, but better than nothing
        Restart = "on-failure";
        RestartSec = 10;

        ExecStart = concatStringsSep " " [
          "${cfg.zeronsd.package}/bin/zeronsd"
          "start"
          "-s /var/lib/zerotier-one/authtoken.secret"
          "-d ${domain}"
          "${network}"
        ];
      };
    };
  };
}
