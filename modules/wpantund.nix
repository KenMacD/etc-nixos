{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.wpantund;
  package = pkgs.wpantund;

in
{
  options.services.wpantund = {
    enable = mkEnableOption "Whether to run the wpantund daemon.";

    # TODO: more options
    socketPath = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = ''
        Path to serial port used to communicate with the NCP.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ package ];

    environment.etc."wpantund.conf".text = ''
      Config:NCP:SocketPath "${cfg.socketPath}"
    '';

    systemd.services.wpantund = {
      description = "wpantund";

      path = [ pkgs.wpantund ];

      serviceConfig = {
        BusName = "com.nestlabs.WPANTunnelDriver";
        Type = "dbus";
        ExecStart = "${pkgs.wpantund}/bin/wpantund -c /etc/wpantund.conf";
      };
    };

    services.dbus.enable = true;
    services.dbus.packages = [ package ];

    systemd.packages = [ package ];
  };
}
