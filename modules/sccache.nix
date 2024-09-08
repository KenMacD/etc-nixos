{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.sccache;
in {
  options.services.sccache = {
    enable = mkEnableOption "sccache server";
  };

  config = mkIf cfg.enable {
    environment.variables.SCCACHE_NO_DAEMON = "1";

    systemd.user.services.sccache = {
      description = "Sccache server";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${pkgs.sccache}/bin/sccache --start-server";
        ExecStop = "${pkgs.sccache}/bin/sccache --stop-server";
        Restart = "on-failure";
        Type = "forking";
      };
      environment = {
        SCCACHE_IDLE_TIMEOUT = "0";
        SCCACHE_CACHE_SIZE = "2G";
      };
    };
  };
}
