{
  self,
  config,
  pkgs,
  lib,
  system,
  modulesPath,
  ...
}: let
  local = self.packages.${system};
in {
  imports = [
    ./hardware.nix
    ./networkd.nix
  ];

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;
  hardware = {};

  ########################################
  # Nix
  ########################################
  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
    extra-substituters = [
      # default priority is 40, lower = checked first
      # For pre-built n8n and zerotier packages
      "https://nix-community.cachix.org?priority=50"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  ########################################
  # Boot
  ########################################
  # CX23 is BIOS-only (confirmed via efibootmgr), so use GRUB not systemd-boot.
  # Must explicitly disable systemd-boot because common.nix sets it as mkDefault true.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = lib.mkForce ["/dev/sda"];

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "hz";
    useNetworkd = true;
    networkmanager.enable = false;
    timeServers = [
      "ntp1.hetzner.de"
      "ntp2.hetzner.com"
      "ntp3.hetzner.net"
    ];
  };
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [config.services.tailscale.interfaceName];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
    allowedTCPPorts = [];
  };

  ########################################
  # Services
  ########################################
  services.tailscale.enable = true;

  # Force tailscaled to use nftables (critical for clean nftables-only systems)
  # Avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  zramSwap.enable = true;

  ########################################
  # Virtualisation
  ########################################
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };

  ########################################
  # User
  ########################################
  users.motd = ''
  '';

  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
  ];
}
