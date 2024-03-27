{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.zerotier-home;
  token = "TOKEN"; # TODO: secretify token:
  domain = "zero.macdermid.ca";
  network = "NETWORK";
  dnsServers = "IP ADDR"; # TODO: sync from ZT console
  ztInterface = "ztINTERFACE";
in {
  options.services.zerotier-home = {
    enable = mkEnableOption "Zerotier network";

    zeronsd = {
      enable = mkEnableOption "Zerotier NS daemon";
      package = mkOption {
        type = types.package;
        description = mkDoc "ZeroNSD Package";
      };
    };
  };

  config = mkIf cfg.enable {
    services.zerotierone = {
      enable = true;
      joinNetworks = [network];
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
        Domains = domain;
        KeepConfiguration = "static";
      };
    };

    systemd.services.zeronsd = mkIf cfg.zeronsd.enable {
      description = "zeronsd";

      wantedBy = ["multi-user.target"];
      after = ["zerotierone.service"];
      requires = ["zerotierone.service"];

      serviceConfig = {
        Type = "simple";

        ExecStart = concatStringsSep " " [
          "${cfg.zeronsd.package}/bin/zeronsd"
          "start"
          "-s /var/lib/zerotier-one/authtoken.secret"
          "-t ${pkgs.writeTextDir "token" token}/token"
          "-d ${domain}"
          "${network}"
        ];
      };
    };
  };
}
