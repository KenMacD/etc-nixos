{
  config,
  pkgs,
  lib,
  ...
}: let
  ip = "172.27.0.3";
  secrets = import ./secrets.nix;
in {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;
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
  sops.secrets.cloudflare = { };
  sops.secrets.oauth2_proxy = { };
  sops.secrets.telegraf = { };

  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

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

  services.postgresql = {
    package = pkgs.postgresql_16;
  };
  services.miniflux = {
    enable = true;
    adminCredentialsFile = "/etc/nixos/miniflux-admin-credentials";
    config = {
      DEBUG = "off";
      LISTEN_ADDR = "127.0.0.1:35001";
      BASE_URL = "https://miniflux.home.macdermid.ca";
      AUTH_PROXY_HEADER = "X-Email";
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
      tls_chain = "/var/lib/acme/home.macdermid.ca/fullchain.pem";
      tls_key = "/var/lib/acme/home.macdermid.ca/key.pem";
    };
    enableClient = true;
    clientSettings = {
      uri = "${config.services.kanidm.serverSettings.origin}";
    };
  };

  systemd.services.oauth2_proxy = {
    after = ["nginx.service" "kanidm.service"];
    requires = ["nginx.service" "kanidm.service"];
  };

  services.oauth2_proxy = let
    clientId = "miniflux";
  in {
    enable = true;
    provider = "oidc";
    scope = "openid email";
    cookie.domain = ".home.macdermid.ca";

    loginURL = "${config.services.kanidm.serverSettings.origin}/ui/oauth2";
    redeemURL = "${config.services.kanidm.serverSettings.origin}/oauth2/token";
    validateURL = "${config.services.kanidm.serverSettings.origin}/oauth2/openid/${clientId}/userinfo";

    clientID = clientId;
    keyFile = config.sops.secrets.oauth2_proxy.path;
    email.domains = ["*"];
    reverseProxy = true;
    passAccessToken = true;
    setXauthrequest = true;

    nginx = {
      proxy = "http://127.0.0.1:4180";
      virtualHosts = [
        "miniflux.home.macdermid.ca"
      ];
    };

    extraConfig = {
      whitelist-domain = ".home.macdermid.ca";
      oidc-issuer-url = "${config.services.kanidm.serverSettings.origin}/oauth2/openid/${clientId}";
      provider-display-name = "Kanidm";
      skip-provider-button = true;
      code-challenge-method = "S256";
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
    extraGroups = ["media" "podman" "dialout"];
  };

  ########################################
  # Containers
  ########################################
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };
  virtualisation.docker.enable = true;

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
      };
      "auth.basic".enabled = "false";
      auth.disable_login_form = "true";
    };
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

  # nginx
  systemd.services.nginx.serviceConfig.SupplementaryGroups = "acme";
  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;

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

        127.0.0.0/8 yes;
        172.27.0.0/24 yes;
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
      "www.home.macdermid.ca" =
        base {
          "/".root = "/etc/nixos/hosts/yoga/www/";
        }
        // {serverAliases = ["home.macdermid.ca"];};
      "bitwarden.home.macdermid.ca" = proxywss config.services.vaultwarden.config.ROCKET_PORT;
      "focalboard.home.macdermid.ca" = proxywss 18000;
      "git.home.macdermid.ca" = {http2 = true;} // proxy config.services.gitea.settings.server.HTTP_PORT;
      "grafana.home.macdermid.ca" = proxywss config.services.grafana.settings.server.http_port;
      "hedgedoc.home.macdermid.ca" = proxy config.services.hedgedoc.settings.port;
      "auth.home.macdermid.ca" = proxytls 9001;
      "influxdb.home.macdermid.ca" = proxy 8086;
      "jellyfin.home.macdermid.ca" = public (proxywss 8096);
      "matrix.home.macdermid.ca" = proxy config.services.matrix-conduit.settings.global.port;
      "nzbget.home.macdermid.ca" = proxy 6789;
      "miniflux.home.macdermid.ca" = proxy 35001;

      "unifi.home.macdermid.ca" = proxytls 8443;
      "immich.home.macdermid.ca" = base {
        "/".proxyPass = "http://127.0.0.1:3550/";
        "/".proxyWebsockets = true;
      };

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
        namepass = ["heat" "thermostat" "weather"];
        urls = ["http://127.0.0.1:8086"];
        token = "$INFLUX_HVAC_WRITE";
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
          "https://api.darksky.net/forecast/$DARK_SKY_API_KEY/$DARK_SKY_API_LOCATION?exclude=alerts%2Cdaily%2Chourly%2Cminutely%2Cflag&units=ca"
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
    settings = {
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
    bcachefs-tools
    btrfs-progs
    dhcpcd
    git
    fwupd
    htop
    kitty # for term info only
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
    jesec-rtorrent

    (let
      # XXX specify the postgresql package you'd like to upgrade to.
      # Do not forget to list the extensions you need.
      newPostgres = pkgs.postgresql_15.withPackages (pp: [
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

    libva-utils
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    (weechat.override {
      configure = {availablePlugins, ...}: {
        plugins = with availablePlugins; [python];
      };
    })
  ];
}
