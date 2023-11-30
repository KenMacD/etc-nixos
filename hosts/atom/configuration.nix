{ config
, pkgs
, ...
}:
let
  ip = "172.27.0.5";
  {
  imports = [
  ];

  ########################################
  # Boot
  ########################################
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.systemd-boot.enable = false;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "atom";
    domain = "home.macdermid.ca";
    firewall = {
      allowedTCPPorts = [ ];
    };
    usePredictableInterfaceNames = true;
    interfaces.enp4s0.ipv4.addresses = [
      {
        address = ip;
        prefixLength = 24;
      }
    ];
    defaultGateway = "172.27.0.1";
    nameservers = [ "172.27.0.1" ];
  };

  ########################################
  # Simple Services
  ########################################
  services = {
    openssh =
      {
        enable = true;
        openFirewall = true;
      };
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs;
    [
      btrfs-progs
      vim
    ];
  }
