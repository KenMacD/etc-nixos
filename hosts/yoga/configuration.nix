{
  config,
  pkgs,
  lib,
  ...
}: let
  ip = "172.27.0.3";
in {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;

  services.rabbitmq = {
    enable = true;
    managementPlugin.enable = true;
    # https://www.rabbitmq.com/mqtt.html
    plugins = ["rabbitmq_management" "rabbitmq_mqtt"];
    configItems = {
      # "ath_backends.abc" = "def;
      # "mqtt.subscription_ttl" = "10000";
      # #"log.default.level" = "warning";
      # "log.connection.level" = "warning";
    };
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
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    focalboard = pkgs.callPackage ../../pkgs/focalboard/default.nix {};
  };

  ########################################
  # Secrets
  ########################################
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.cloudflare = {};
  sops.secrets.nix-cache-key= {};
  sops.secrets.miniflux = {};
  sops.secrets.telegraf = {};

  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = false;
  boot.tmp.tmpfsSize = "90%";

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;

    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv4.conf.all.proxy_arp" = true;
  };
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
        8200 # minidlna
      ];
      # upnp
      allowedUDPPorts = [
        53 # DNS - Todo: make on podman only
        1900 # UPnP
        8089 # telegraf thermostat
      ];
    };
    interfaces.wlan0.useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = ip;
        prefixLength = 24;
      }
    ];
    defaultGateway = "172.27.0.1";
    nameservers = ["172.27.0.1"];
  };

  # To access from dbeaver forward to socket:
  # ssh kenny@yoga -L 35432:/var/run/postgresql/.s.PGSQL.5432
  services.postgresql = {
    # TODO: Testing JIT package... does it help?
    package = pkgs.postgresql_16_jit;
    enableJIT = true;
    authentication = ''
      local all all ident map=mapping
    '';
    identMap = ''
      mapping kenny    postgres
      mapping root     postgres
      mapping postgres postgres
      mapping /^(.*)$  \1
    '';
    settings = {
      # Set larger query size to see immich queries
      # default: 1024
      track_activity_query_size = "64kB";

      # Trying https://pgtune.leopard.in.ua/#/
      # DB Version: 16
      # OS Type: linux
      # DB Type: mixed
      # Total Memory (RAM): 4 GB
      # CPUs num: 4
      # Data Storage: hdd
      max_connections = "100";
      shared_buffers = "1GB";
      effective_cache_size = "3GB";
      maintenance_work_mem = "256MB";
      checkpoint_completion_target = "0.9";
      wal_buffers = "16MB";
      default_statistics_target = "100";
      random_page_cost = "4";
      effective_io_concurrency = "2";
      work_mem = "2621kB";
      huge_pages = "off";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = "4";
      max_parallel_workers_per_gather = "2";
      max_parallel_workers = "4";
      max_parallel_maintenance_workers = "2";
    };
  };

  services.miniflux = {
    enable = true;
    adminCredentialsFile =  config.sops.secrets.miniflux.path;
    config = {
      DEBUG = "off";
      LISTEN_ADDR = "127.0.0.1:35001";
      BASE_URL = "https://miniflux.home.macdermid.ca";
#      AUTH_PROXY_HEADER = "X-Email";
      OAUTH2_PROVIDER="oidc";
      OAUTH2_CLIENT_ID="miniflux";
      OAUTH2_REDIRECT_URL="https://miniflux.home.macdermid.ca/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT="https://auth.home.macdermid.ca/oauth2/openid/miniflux";
#      OAUTH2_USER_CREATION=1
    };
  };
  services.avahi.publish = {
    enable = true;
    addresses = true;
    userServices = true;
  };
  services.fwupd.enable = true;

  systemd.services.kanidm.serviceConfig.SupplementaryGroups = "acme";
  services.kanidm = {
    enableServer = true;
    serverSettings = {
      bindaddress = "127.0.0.1:9001";
      ldapbindaddress = "127.0.0.1:636";
      origin = "https://auth.home.macdermid.ca";
      domain = "auth.home.macdermid.ca";
      # log_level = "debug";
      tls_chain = "/var/lib/acme/home.macdermid.ca/fullchain.pem";
      tls_key = "/var/lib/acme/home.macdermid.ca/key.pem";
    };
    enableClient = true;
    clientSettings = {
      uri = "${config.services.kanidm.serverSettings.origin}";
    };
  };

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
    logind.lidSwitch = "ignore";
    openssh = {
      enable = true;
      # passwordAuthentication = true;
    };
    thermald.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    nix-serve = {
      enable = true;
      bindAddress = "127.0.0.1";
      secretKeyFile = config.sops.secrets.nix-cache-key.path;
    };
  };

  ########################################
  # User
  ########################################
  users.users.kenny = {
    extraGroups = [
      "dialout"
      "libvirtd"
      "media"
      "podman"
    ];
  };

  ########################################
  # Containers
  ########################################
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    # defaultNetwork.settings.dns_enabled.enable = true;
  };
  virtualisation.docker.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf = {
      enable = true;
    };
    # Only care about host arch:
    qemu.package = pkgs.qemu_kvm;
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
        enabled = true;
        org_name = "MacDermid";
        org_role = "Editor";
        # org_role = "Admin";
      };
      "auth.basic".enabled = "false";
      auth.disable_login_form = "true";
    };
  };

  services.prometheus = {
    enable = true;
    port = 9091;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9092;
      };
      smartctl = {
        enable = true;
        port = 9093;
      };
    };

    scrapeConfigs = [
      {
        job_name = "yoga";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "yoga-smart";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"];
          }
        ];
      }
    ];
  };

  services.gitea = {
    enable = true;
    stateDir = "/mnt/easy/yoga-var-lib/gitea";

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
      security = {
        REVERSE_PROXY_AUTHENTICATION_EMAIL = "X-Email";
      };
      service = {
        ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
      };
      server = {
        DOMAIN = "git.home.macdermid.ca";
        HTTP_PORT = 3001;
        HTTP_ADDRESS = "127.0.0.1";
        ROOT_URL = "https://git.home.macdermid.ca/";
      };
      log.LEVEL = "Warn";
      service.DISABLE_REGISTRATION = true; # After creating my account
      session.COOKIE_SECURE = true;
    };
  };
  systemd.services.gitea.unitConfig.RequiresMountsFor = config.services.gitea.stateDir;

  services.jellyfin = {
    enable = true;
    openFirewall = false;
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
      credentialsFile = config.sops.secrets.cloudflare.path;
      dnsResolver = "1.1.1.1:53";
    };
    certs."home.macdermid.ca" = {
      domain = "*.home.macdermid.ca";
      extraDomainNames = ["home.macdermid.ca"];
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
        cleanup_second_interval = 60 * 60;
      };
    };
  };

  services.zerotierone.enable = true;
  systemd.services.zerotierone.serviceConfig = {
    KillMode = lib.mkForce "control-group";
    TimeoutStopFailureMode = "kill";
  };

  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi8;
    openFirewall = true;
  };

  services.cockpit = {
    enable = true;
    openFirewall = false;
    settings = {
      Webservice = {
        Origins = "https://cockpit.home.macdermid.ca";
      };
    };
  };

  # nginx
  systemd.services.nginx.serviceConfig.SupplementaryGroups = "acme";
  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;

    serverTokens = false;

    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    # recommendedTlsSettings = true;
    sslProtocols = "TLSv1.3";

    # Internal only, allow immich video upload:
    clientMaxBodySize = "10g";

    # See recommendedTlsSettings, but set session tickets because nginx is newer
    # See https://github.com/mozilla/server-side-tls/issues/284
    # See https://webdock.io/en/docs/how-guides/security-guides/how-to-configure-security-headers-in-nginx-and-apache
    commonHttpConfig = ''
      ########################################
      ssl_session_timeout 1d;
      ssl_prefer_server_ciphers off;

      # OCSP stapling
      ssl_stapling on;
      ssl_stapling_verify on;

      ########################################
      geo $internal {
        default no;

        fd3e:fa5c:b78a:1548:d599:9300::/88 yes;
        127.0.0.0/8 yes;
        172.27.0.0/24 yes;

        # TODO: move podman network? Or at least put a value here?
        10.88.0.0/16 yes;
      }

      ########################################
      # https://github.com/MidAutumnMoon/Nuran/blob/fbf3f38169c70eadbd72aaec4e07db3c8ea485be/nixos/web/server/nginx/configfile.nix#L116
      more_clear_headers Server;
      more_clear_headers X-Powered-By;
      more_clear_headers X-Application-Version;
      more_set_headers 'X-Content-Type-Options: nosniff';
      more_set_headers 'X-XSS-Protection: 1; mode=block';
      more_set_headers 'Strict-Transport-Security: max-age=31536000; includeSubDomains; preload';
      more_set_headers 'X-Frame-Options: SAMEORIGIN';
      more_set_headers 'Referrer-Policy: strict-origin';

      # Enable CSP for your services.
      # add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # This might create errors
      # proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    virtualHosts = let
      base = locations: let
        inherit (config.security.acme) certs;
        certName = "home.macdermid.ca";
      in {
        inherit locations;
        onlySSL = true;

        http2 = true;
        http3 = true;
        quic = true;

        # Copied from nginx/default.nix to avoid having a
        # .well-known/acme-challenge/ entry in the nginx config.
        sslCertificate = "${certs.${certName}.directory}/fullchain.pem";
        sslCertificateKey = "${certs.${certName}.directory}/key.pem";
        sslTrustedCertificate = "${certs.${certName}.directory}/chain.pem";

        extraConfig = ''
          if ($internal != yes) {
            return 404;
          }
        '';
      };
      public = config: builtins.removeAttrs config ["extraConfig"];
      proxy = port:
        base {
          "/".proxyPass = "http://127.0.0.1:${toString port}";
        };
      proxywss = port:
        base {
          "/".proxyPass = "http://127.0.0.1:${toString port}";
          "/".proxyWebsockets = true;
        };
      proxytls = port:
        base {
          "/".proxyPass = "https://127.0.0.1:${toString port}";
        };
    in {
      "_" =
        {default = true;}
        // base {
          "/".return = "444";
        };
      "auth.home.macdermid.ca" = proxytls 9001;
      "www.home.macdermid.ca" =
        base {
          "/".root = "/etc/nixos/hosts/yoga/www/";
        }
        // {serverAliases = ["home.macdermid.ca"];};
      "bitwarden.home.macdermid.ca" = proxywss config.services.vaultwarden.config.ROCKET_PORT;
      "cockpit.home.macdermid.ca" = proxywss config.services.cockpit.port;
      "focalboard.home.macdermid.ca" = proxywss 18000;
      "git.home.macdermid.ca" = {http2 = true;} // proxy config.services.gitea.settings.server.HTTP_PORT;
      "grafana.home.macdermid.ca" = proxywss config.services.grafana.settings.server.http_port;
      "immich.home.macdermid.ca" = base {
        "/".proxyPass = "http://127.0.0.1:3550/";
        "/".proxyWebsockets = true;
      };
      "influxdb.home.macdermid.ca" = proxy 8086;
      "jellyfin.home.macdermid.ca" = public (proxywss 8096);
      "matrix.home.macdermid.ca" = proxy config.services.matrix-conduit.settings.global.port;
      "miniflux.home.macdermid.ca" = proxy 35001;
      "nzbget.home.macdermid.ca" = proxy 6789;
      "nginxstatus.home.macdermid.ca" = base {
        "/".extraConfig = ''
          stub_status on;
          access_log off;
        '';
      };
      "nix.home.macdermid.ca" = proxy config.services.nix-serve.port;
      "rabbitmq.home.macdermid.ca" = proxy config.services.rabbitmq.managementPlugin.port;
      "unifi.home.macdermid.ca" = proxytls 8443;
    };
  };

  # TODO: backup nzbget config
  services.nzbget = {
    enable = true;
  };
  systemd.services.nzbget.path = with pkgs; [
    unrar
    p7zip
    python39 # TODO: when videosort updated, update python
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
    environmentFiles = [
      config.sops.secrets.telegraf.path
    ];
    extraConfig = {
      outputs.influxdb_v2 = {
        #        namepass = ["heat" "thermostat" "weather"];
        urls = ["http://127.0.0.1:8086"];
        token = "$INFLUX_HVAC_WRITE";
        #token = secrets.INFLUX_HVAC_WRITE;
        organization = "macdermid";
        bucket = "telegraf";
      };
      inputs.socket_listener = {
        service_address = "udp://:8089";
        data_format = "influx";
      };
      inputs.nginx = [{urls = ["https://nginxstatus.home.macdermid.ca/"];}];
    };
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    bcachefs-tools
    btrfs-progs
    dhcpcd
    exiftool
    fd
    fwupd
    git
    htop
    immich-cli
    immich-go # local
    jesec-rtorrent
    kitty # for term info only
    libva-utils
    mediainfo
    ncdu
    nixfmt
    powertop
    pstree
    restic
    rmlint
    tmux
    (weechat.override {
      configure = {availablePlugins, ...}: {
        plugins = with availablePlugins; [python];
      };
    })
    wpa_supplicant
    yt-dlp

    # for nzbget
    unrar
    p7zip
    python3

    # for postgresql upgrade
    (let
      # XXX specify the postgresql package you'd like to upgrade to.
      # Do not forget to list the extensions you need.
      newPostgres =
        pkgs.postgresql_15.withPackages (pp: [
        ]);
    in
      pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"

        export NEWBIN="${newPostgres}/bin"

        export OLDDATA="${config.services.postgresql.dataDir}"
        export OLDBIN="${config.services.postgresql.package}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      '')
  ];
}
