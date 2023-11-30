{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.zerotier-home;
in {
  options.services.zerotier-home = {
    enable = mkEnableOption "Zerotier home network";
    jail = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Should teams be Wrapped with firejail
      '';
    };
  };

  config = mkIf cfg.enable {
    services.zerotierone = {
      enable = true;
      joinNetworks = ["<NETWORK>"];
    };

    systemd.services.zerotierone.serviceConfig = {
      KillMode = lib.mkForce "control-group";
      TimeoutStopFailureMode = "kill";
    };

#    networking.extraHosts = concatStringsSep "\n" (map
#      (host: "<IP> ${host}.${config.networking.domain}")
#      [
#      ]);
#  };
}
