{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedUDPPorts = [
    69 # tftp

    3478
    4379
    4380

    24642 # Stardew
  ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 27000;
      to = 27100;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 27000;
      to = 27100;
    }
  ];
  networking.firewall.trustedInterfaces = [
    "docker0"
  ];
  networking.firewall.allowedTCPPorts = [
    27036 # Steam
    24642 # Stardew
  ];

  programs.steam.remotePlay.openFirewall = true;
}
