{ config, pkgs, ... }:

let
  ip = "172.27.0.3";
in
{
  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = true;
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  powerManagement.enable = true;

  ########################################
  # ZFS
  ########################################
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.trim.enable = true;
  services.zfs.autoSnapshot.enable = true;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "cubie";
    domain = "local";
    hostId = "f5a3f353";
    firewall = {
      # grafana, nzbget, test, minidlna, portainer
      allowedTCPPorts = [ 80 3000 6789 8080 8200 9000 ];
      # upnp
      allowedUDPPorts = [ 1900 ];
    };
    interfaces.wlan0.useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address = ip;
      prefixLength = 24;
    }];
    defaultGateway = "172.27.0.1";
    nameservers = [ "1.0.0.1" "1.1.1.1" ];
  };

  services.avahi.publish = {
    enable = true;
    addresses = true;
  };
  services.unbound.enable = true;

  ########################################
  # Users
  ########################################
  users.groups.media.members = [ "minidlna" "nzbget" ];

  ########################################
  # Services
  ########################################
  services = {
    openssh.enable = true;
    logind.lidSwitch = "ignore";
  };

  ########################################
  # User
  ########################################
  programs.vim.defaultEditor = true;
  users.users.kenny = {
    extraGroups = [ "docker" ];
  };

  ########################################
  # Containers
  ########################################
  virtualisation.docker = {
    enable = true;
    liveRestore = false;  # using swarm
  };

  ########################################
  # Services
  ########################################
  # Grafana
  services.grafana = {
    enable = true;
    rootUrl = "http://${config.networking.fqdn}/grafana/";
  };

  # nginx
  services.nginx = {
    enable = true;

    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."${config.networking.fqdn}" = {
      locations = {
        "/grafana/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}/";
        };
        "/nzbget/" = {
          proxyPass = "http://127.0.0.1:6789/";
        };
      };
    };
  };

  # TODO: backup nzbget config
  services.nzbget = {
    enable = true;
  };

  # Minidlna
  services.minidlna = {
    enable = true;

    announceInterval = 60;
    friendlyName = "Cubie";
    loglevel = "info";
    mediaDirs = [
     "V,/mnt/multimedia/incoming"
     "V,/mnt/multimedia/films"
     "V,/mnt/multimedia/tv"
    ];
    rootContainer = "V";

    extraConfig = ''
      network_interface=eth0
    '';
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    btrfs-progs
    dhcpcd
    htop
    kitty  # for term info only
    ncdu
    nixfmt
    powertop
    pstree
    tmux
    wpa_supplicant
  ];
}

