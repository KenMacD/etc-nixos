{ config, pkgs, lib,  ... }:

let
  ip = "172.27.0.3";
  secrets = import ./secrets.nix;
in
{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  system.autoUpgrade.enable = true;
  hardware = {
    bluetooth.enable = true;
    opengl = {
      enable = true;
      driSupport = true; # for vulkan
      driSupport32Bit = true;
      setLdLibraryPath = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime  # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    focalboard = pkgs.callPackage ../../pkgs/focalboard/default.nix {};
  };

  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
  boot.kernelPackages = pkgs.linuxPackages_6_2;

  powerManagement.enable = true;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "yoga";
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
    nameservers = [ "45.90.28.215" "45.90.30.215" ];
  };

  services.miniflux = {
    enable = true;
    adminCredentialsFile = "/etc/nixos/miniflux-admin-credentials";
    config = {
      DEBUG = "off";
      LISTEN_ADDR = "127.0.0.1:35001";
      BASE_URL = "https://miniflux.home.macdermid.ca";
    };
  };
  services.avahi.publish = {
    enable = true;
    addresses = true;
    userServices = true;
  };
  services.fwupd.enable = true;

  ########################################
  # Users
  ########################################
  users.groups.media.members = with config.systemd.services; [
    jellyfin.serviceConfig.User
    minidlna.serviceConfig.User
    nzbget.serviceConfig.User
  ];
  users.groups.render.members = with config.systemd.services; [
    jellyfin.serviceConfig.User
  ];

  ########################################
  # Simple Services
  ########################################
  services = {
    openssh = {
      enable = true;
    };
    logind.lidSwitch = "ignore";
    thermald.enable = true;
    udisks2.enable = true;
    upower.enable = true;
  };

  ########################################
  # User
  ########################################
  users.users.kenny = {
    extraGroups = [ "media" "podman" "dialout"];
  };

  ########################################
  # Containers
  ########################################
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled.enable = true;
  };

  ########################################
  # Complex Services
  ########################################
  # Grafana
  services.grafana = {
    enable = true;
    settings = {
      server.rootUrl = "https://grafana.home.macdermid.ca/";
      server.domain = "grafana.home.macdermid.ca";
      "auth.anonymous" = {
        enable = true;
        org_name = "MacDermid";
        org_role = "Editor";
      };
      "auth.basic".enabled = "false";
      auth.disable_login_form = "true";
    };
  };

  services.gitea = {
    enable = true;

    settings = {
      "git.timeout" = {
        DEFAULT = 50000;
        MIGRATE = 50000;
        MIRROR = 50000;
        CLONE = 50000;
        PULL = 50000;
        GC = 50000;
#        MIGRATE = 2400;
      };
      server = {
        DOMAIN = "git.home.macdermid.ca";
        HTTP_PORT = 3001;
        HTTP_ADDRESS = "127.0.0.1";
        ROOT_URL = "https://git.home.macdermid.ca/";
      };
      log.LEVEL = "Warn";
      service.DISABLE_REGISTRATION = true;  # After creating my account
      session.COOKIE_SECURE = true;
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.jellyfin.environment."JELLYFIN_PublishedServerUrl" = "https://jellyfin.home.macdermid.ca";

  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://bitwarden.home.macdermid.ca";
      SIGNUPS_ALLOWED = true;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";

    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "kenny@macdermid.ca";
      dnsProvider = "cloudflare";
      # TODO: fix
      credentialsFile = ./. + "/cloudflare.env";
      dnsResolver = "1.1.1.1:53";
    };
    certs."home.macdermid.ca" = {
      domain = "*.home.macdermid.ca";
    };
  };
  services.matrix-conduit = {
    enable = true;
    settings = {
      global = {
        address = "127.0.0.1";
        allow_registration = true;
        server_name = "macdermid.ca";
        allow_federation = false;
      };
    };
  };

  services.zerotierone.enable = true;
  systemd.services.zerotierone.serviceConfig = {
    KillMode = lib.mkForce "control-group";
    TimeoutStopFailureMode = "kill";
  };

  # nginx
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
      add_header X-Frame-Options SAMEORIGIN;

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
        useACMEHost = "home.macdermid.ca";
      };
      proxy = port: base {
        "/".proxyPass = "http://127.0.0.1:${toString port}/";
      };
      proxywss = port: base {
        "/".proxyPass = "http://127.0.0.1:${toString port}/";
        "/".proxyWebsockets = true;
      };
    in {
      "home.macdermid.ca" = {
         enableACME = true;
         acmeRoot = null;
      };
      "www.home.macdermid.ca" =  base  {
        "/".root = "/etc/nixos/hosts/yoga/www/";
      };
      "bitwarden.home.macdermid.ca" = proxywss config.services.vaultwarden.config.ROCKET_PORT;
      "focalboard.home.macdermid.ca" = proxywss 18000;
      "git.home.macdermid.ca" = {http2=true;} //proxy config.services.gitea.settings.server.HTTP_PORT;
      "grafana.home.macdermid.ca" = proxywss config.services.grafana.settings.server.http_port;
      "hedgedoc.home.macdermid.ca" = proxy config.services.hedgedoc.settings.port;
      "influxdb.home.macdermid.ca" = proxy 8086;
      "jellyfin.home.macdermid.ca" = proxywss 8096;
      "matrix.home.macdermid.ca" = proxy config.services.matrix-conduit.settings.global.port;
      "nzbget.home.macdermid.ca" = proxy 6789;
      "miniflux.home.macdermid.ca" = proxy 35001;
    };
  };

  # TODO: backup nzbget config
  services.nzbget = {
    enable = true;
  };
  systemd.services.nzbget.path = with pkgs; [
    unrar
    p7zip
    python3
  ];

  # Minidlna
  services.minidlna = {
    enable = true;

    settings = {
      notify_interval = 60;
      friendly_name = "Cubie";
      log_level = "info";
      media_dir = [
       "V,/mnt/multimedia/incoming"
       "V,/mnt/multimedia/films"
       "V,/mnt/multimedia/tv"
      ];
      root_container = "V";
      network_interface = "eth0";
    };
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
    settings= {
      domain = "hedgedoc.home.macdermid.ca";
      host = "127.0.0.1";
      port = 8090;
      protocolUseSSL = true;
      db = {
        dialect = "sqlite";
        storage = "/var/lib/hedgedoc/db.hedgedoc.sqlite";
      };
      defaultPermission = "private";
      sessionSecret = secrets.HEDGEDOC_SESSION_SECRET;
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
    yt-dlp

    # for nzbget
    unrar
    p7zip
    python3

    screen
    focalboard

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    (weechat.override {
      configure = { availablePlugins, ... }: {
        plugins = with availablePlugins; [ python ];
      };
    })
  ];
}
