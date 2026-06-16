{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.network.enable = true;

  networking.usePredictableInterfaceNames = true;

  networking.useHostResolvConf = lib.mkDefault (!config.systemd.network.enable);
  networking.resolvconf.dnsSingleRequest = true;

  # DHCP via systemd-networkd for Hetzner Cloud
  # Matches ANY ethernet interface by Type, making this config portable
  # across multiple Hetzner VPS hosts (each has different MAC/name).
  # Safe for single-interface CX/CCX VPS instances.
  # For multi-interface hosts, override with a host-specific network config
  # using matchConfig.MACAddress.
  systemd.network.networks."10-lan" = {
    matchConfig.Type = "ether";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = true;
    };
  };
}
