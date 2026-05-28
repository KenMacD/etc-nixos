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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  ########################################
  # Services
  ########################################
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
