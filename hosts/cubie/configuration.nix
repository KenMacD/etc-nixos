{ config, pkgs, ... }:

let
  ip = "172.27.0.3";
  secrets = import ./secrets.nix;
in
{
  imports = [ ./influxdb2.nix ];  # Remove once 21.11

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
      allowedTCPPorts = [
        80
        8086  # influxdb
        8200  # minidlna
        9000  # portainer
      ];
      # upnp
      allowedUDPPorts = [
        1900  # UPnP
        8089  # telegraf thermostat
      ];
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
  services.fwupd.enable = true;

  ########################################
  # Users
  ########################################
  users.groups.media.members = [ "minidlna" "nzbget" ];

  ########################################
  # Simple Services
  ########################################
  services = {
    openssh.enable = true;
    logind.lidSwitch = "ignore";
  };

  ########################################
  # User
  ########################################
  users.users.kenny = {
    extraGroups = [ "media" "docker"];
  };

  ########################################
  # Containers
  ########################################
  virtualisation.docker = {
    enable = true;
    liveRestore = false;  # using swarm
  };

  ########################################
  # Complex Services
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

  services.influxdb2 = {
    enable = true;
    settings = {
      log-level = "error";
    };
  };

  services.telegraf = {
    enable = true;
    extraConfig = {
      outputs.influxdb_v2 = {
        namepass = [ "heat" "thermostat" "weather" ];
        urls = [ "http://127.0.0.1:8086" ];
        token = secrets.INFLUX_HVAC_WRITE;
        organization = "macdermid";
        bucket = "hvac";
      };
      inputs.socket_listener = {
        service_address = "udp://:8089";
        data_format = "influx";
      };
      inputs.http = {
        interval = "5m";
        name_override = "weather";
        urls = [
          "https://api.darksky.net/forecast/${secrets.DARK_SKY_API_KEY}/${secrets.DARK_SKY_API_LOCATION}?exclude=alerts%2Cdaily%2Chourly%2Cminutely%2Cflag&units=ca"
        ];
        data_format = "json";
        json_query = "currently";
        json_string_fields = [
          "icon"
          "precipType"
          "summary"
        ];
        json_time_key = "time";
        json_time_format = "unix";
      };
    };
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    btrfs-progs
    dhcpcd
    git
    fwupd
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

