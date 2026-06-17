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

  # DHCP via systemd-networkd for Hetzner Cloud.
  # Match physical NICs by NAME (en*), NOT by Type="ether". A podman/netavark
  # veth is Kind=veth but Type=ether, so a Type="ether" match also catches it:
  # networkd then seizes the veth, runs DHCP on it, and tears it off the
  # podman0 bridge right after netavark enslaves it -> podman0 goes NO-CARRIER
  # and containers lose all L2 connectivity (even to their own gateway).
  # Name="en*" covers enp*/ens*/eno*/enx* (all predictable-name physical NICs
  # on Hetzner Cloud NixOS) and naturally excludes veth*/podman*/tailscale0/br*.
  # For multi-interface hosts, override with a host-specific network config
  # using matchConfig.MACAddress.
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "en*";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = true;
    };
  };
}
