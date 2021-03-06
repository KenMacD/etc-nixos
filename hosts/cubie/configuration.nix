{ config, pkgs, lib,  ... }:

let
  ip = "172.27.0.3";
  secrets = import ./secrets.nix;
in
{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  system.autoUpgrade.enable = true;
  nixpkgs.config.packageOverrides = pkgs: {
    focalboard = pkgs.callPackage ../../pkgs/focalboard/default.nix {};
  };

  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = true;
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  powerManagement.enable = true;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "cubie";
    domain = "home.macdermid.ca";
    hostId = "f5a3f353";
    firewall = {
      # grafana, nzbget, test, minidlna, portainer
      allowedTCPPorts = [
        80
        443
        8200  # minidlna
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
    userServices = true;
  };
  services.unbound.enable = true;
  services.fwupd.enable = true;

  ########################################
  # Users
  ########################################
  users.groups.media.members = with config.systemd.services; [
    minidlna.serviceConfig.User
    nzbget.serviceConfig.User
  ];

  ########################################
  # Simple Services
  ########################################
  services = {
    openssh = {
      enable = true;
    };
    logind.lidSwitch = "ignore";
  };

  ########################################
  # User
  ########################################
  users.users.kenny = {
    extraGroups = [ "media" "docker" "dialout"];
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
  services.grafana = rec {
    enable = true;
    rootUrl = "http://${config.services.grafana.domain}/";
    domain = "grafana.home.macdermid.ca";
    auth = {
      anonymous = {
        enable = true;
        org_name = "MacDermid";
        org_role = "Editor";
      };
    };
    extraOptions = {
      auth_basic_enabled = "false";
      auth_disable_login_form = "true";
    };
  };

  # nginx
  environment.etc = {
    nginx-cert = {
      text = secrets.NGINX_CERT;
      mode = "0444";
      user = config.systemd.services.nginx.serviceConfig.User;
      group= config.systemd.services.nginx.serviceConfig.Group;
    };
    nginx-cert-key = {
      text = secrets.NGINX_CERT_KEY;
      mode = "0400";
      user = config.systemd.services.nginx.serviceConfig.User;
      group= config.systemd.services.nginx.serviceConfig.Group;
    };
  };
  services.nginx = {
    enable = true;

    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    commonHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      # May be unnecessary when CSP is configured properly (see above)
      add_header X-XSS-Protection "1; mode=block";

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    virtualHosts = let
      base = locations: {
        inherit locations;
        forceSSL = true;
        sslCertificate = "/etc/nginx-cert";
        sslCertificateKey = "/etc/nginx-cert-key";
      };
      proxy = port: base {
        "/".proxyPass = "http://127.0.0.1:${toString port}/";
      };
      proxywss = port: base {
        "/".proxyPass = "http://127.0.0.1:${toString port}/";
        "/".proxyWebsockets = true;
      };
    in {
      "www.home.macdermid.ca" =  base  {
        "/".root = "/etc/nixos/hosts/cubie/www/";
      };
      "grafana.home.macdermid.ca" = proxywss config.services.grafana.port;
      "influxdb.home.macdermid.ca" = proxy 8086;
      "nzbget.home.macdermid.ca" = proxy 6789;
      "hedgedoc.home.macdermid.ca" = proxy config.services.hedgedoc.configuration.port;
      "matrix.home.macdermid.ca" = proxy config.services.dendrite.httpPort;
      "focalboard.home.macdermid.ca" = proxywss 18000;
    };
  };

  # TODO: backup nzbget config
  services.nzbget = {
    enable = true;
  };
  systemd.services.nzbget.path = with pkgs; [
    unrar
    p7zip
    python2
  ];

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

  services.hedgedoc = {
    enable = true;
    configuration = {
      domain = "hedgedoc.home.macdermid.ca";
      host = "127.0.0.1";
      port = 8090;
      protocolUseSSL = true;
      db = {
        dialect = "sqlite";
        storage = "/var/lib/hedgedoc/db.hedgedoc.sqlite";
      };
      sessionSecret = secrets.HEDGEDOC_SESSION_SECRET;
    };
  };

  services.dendrite = {
    enable = true;
    settings.global = {
      server_name = "matrix.home.macdermid.ca";
      private_key = "/var/lib/dendrite/matrix_key.pem";
      trusted_third_party_id_servers = [];
      disable_federation = true;

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

