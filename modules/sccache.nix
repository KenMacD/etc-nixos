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

  # Test with: SCCACHE_LOG=trace SCCACHE_SERVER_UDS=/run/user/1001/sccache.sock sccache --show-stats
  config = mkIf cfg.enable {
    environment.variables = {
      SCCACHE_NO_DAEMON = "1";
      SCCACHE_SERVER_UDS = ''''${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}/sccache.sock'';

      # CARGO_BUILD_RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
      RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    };

    environment.systemPackages = [
      pkgs.sccache
    ];

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
        SCCACHE_SERVER_UDS = "%t/sccache.sock";
      };
    };
  };
}
