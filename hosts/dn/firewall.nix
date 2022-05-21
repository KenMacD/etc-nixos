{ config, lib, pkgs, ... }: {

  networking.firewall.allowedUDPPorts = [
    69  # tftp

    3478
    4379
    4380
  ];
  networking.firewall.allowedTCPPortRanges = [
    {from = 27000; to = 27100;}
  ];
  networking.firewall.allowedUDPPortRanges = [
    {from = 27000; to = 27100;}
  ];
  networking.firewall.trustedInterfaces = [
    "docker0"
  ];
  networking.firewall.allowedTCPPorts = [ 27036 ];

  programs.steam.remotePlay.openFirewall = true;
}
