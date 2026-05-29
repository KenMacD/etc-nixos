{pkgs, ...}:
# TODO: make a proper module with enable
{
  systemd.services.whisper-cpp = {
    wants = ["network-online.target"];
    after = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.ffmpeg];
    serviceConfig = {
      DynamicUser = true;
      User = "whisper-cpp";
      ExecStart = [
        (
          "${pkgs.whisper-cpp-vulkan}/bin/whisper-server"
          + " --host 127.0.0.1 --port 8014"
          + " --inference-path /v1/audio/transcriptions --convert"
          + " --model /var/lib/whisper/ggml-large-v3-q5_0.bin"
        )
      ];
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = []; # full offline
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = ["@system-service" "~@privileged"];
      UMask = "0077";
      WorkingDirectory = "/tmp/";
    };
  };
}
