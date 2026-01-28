{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.voxinput;
in {
  options.services.voxinput = {
    enable = mkEnableOption "voxinput voice to text service";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.voxinput
    ];

    environment.etc."sway/config.d/voxinput.conf".source = pkgs.writeText "voxinput.conf" ''
      bindsym $mod+Shift+t exec voxinput record
      bindsym $mod+t exec voxinput write
    '';

    # podman run --detach --name local-ai -p 8014:8080 -v localai-models:/models -v localai-backends:/backends -v /dev/dri:/dev/dri docker.io/localai/localai:latest-gpu-intel
    systemd.user.services.voxinput = {
      description = "VoxInput - Voice to text service";
      wantedBy = ["default.target"];
      # wantedBy = ["graphical-session.target"];
      # partOf = ["graphical-session.target"];
      environment = {
        VOXINPUT_BASE_URL = "http://127.1:8014/v1";
        VOXINPUT_TRANSCRIPTION_MODEL = "whisper-base-en";
      };
      serviceConfig = {
        ExecStart = "${pkgs.voxinput}/bin/voxinput listen --no-realtime";
        Restart = "on-failure";
      };
    };
  };
}
