{ lib, pkgs, config, ... }:

with lib;
let cfg = config.services.avahi-alias;
in {

  options.services.avahi-alias = {
    enable = mkEnableOption "avahi name aliases";
    names = mkOption {
      type = with types; types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {

    systemd.services = listToAttrs (map (name: {
      name = "avahi-${name}";
      value = {
        serviceConfig = {
          ExecStart = "${pkgs.avahi}/bin/avahi-publish -a -R ${name}.local ${
              (elemAt config.networking.interfaces.eth0.ipv4.addresses
                0).address
            }";

        };
        requires = [ "avahi.service" ];
        wantedBy = [ "multi-user.target" ];
      };
    }) cfg.names);
  };
}
