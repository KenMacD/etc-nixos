{
  self,
  config,
  pkgs,
  lib,
  system,
  ...
}: let
  local = self.packages.${system};

  # tailscaled being "active" only means the daemon started, not that the node
  # is logged in; tailscale-serve-* units gate on actual connectivity.
  waitTailscale = pkgs.writeShellScriptBin "wait-tailscale-connected" ''
    for i in $(seq 1 60); do
      if ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; then
        exit 0
      fi
      sleep 1
    done
    echo "wait-tailscale-connected: tailscale not up after 60s" >&2
    exit 1
  '';
in {
  imports = [
    ./networkd.nix

    ./../../modules/litellm.nix
  ];

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;
  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      # From https://nixos.wiki/wiki/Jellyfin
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        vpl-gpu-rt
      ];
    };
  };

  ########################################
  # Secrets
  ########################################
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.cloudflare-tunnel = {};
  sops.secrets.cloudflare = {}; # Cloudflare API token (Zone:DNS:Edit) for ACME DNS-01
  sops.secrets.bigagi = {};
  sops.secrets.kanidm-tls-chain = {
    owner = "kanidm";
    group = "kanidm";
  };
  sops.secrets.kanidm-tls-key = {
    owner = "kanidm";
    group = "kanidm";
  };

  ########################################
  # Nix
  ########################################
  nix.settings = {
    trusted-users = ["root" "@wheel"];
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
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  powerManagement.enable = true;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "r1pro";
    useNetworkd = true;
    # wireless.enable = false;
    networkmanager.enable = false;
    #domain = "home.macdermid.ca";
    # TODO: set?
    #hostId = "f5a3f353";
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [443];
    allowedUDPPorts = [
      5353 # mDNS
      5355 # LLMNR (Link-Local Multicast Name Resolution)
    ];
    trustedInterfaces = ["tailscale0"];
    interfaces."tailscale0".allowedTCPPorts = [
      443 # Serve?
    ];
  };

  ########################################
  # Services
  ########################################
  # Rebuild from the flake source captured at deploy time (self.outPath)
  system.autoUpgrade = {
    enable = false;
    flake = self.outPath;
    flags = [
      "--recreate-lock-file"
      "-L" # print build logs
    ];
    dates = "03:30";
    randomizedDelaySec = "45min";
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "r1pro" = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
        default = "http_status:404";
      };
    };
  };
  systemd.services.cloudflared-tunnel-r1pro = {
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      RestartSec = "30s";
    };
  };
  services.fwupd.enable = true;
  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };
  systemd.services.jellyfin = {
    environment = {
      JELLYFIN_PublishedServerUrl = "https://jellyfin.home.macdermid.ca";
    };
    serviceConfig = {
      CapabilityBoundingSet = "";
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectHome = true;
      # TODO: review 'true' in module ProtectSystem = "strict";
      ProtectClock = true;
      ReadWritePaths = [
        "/srv/media"
        config.services.jellyfin.dataDir
        config.services.jellyfin.configDir
        config.services.jellyfin.cacheDir
        config.services.jellyfin.logDir
      ];
    };
  };
  services.kanidm = {
    # Before upgrade test: sudo -u kanidm -g kanidm kanidmd domain upgrade-check
    package = pkgs.kanidm_1_10;
    server = {
      enable = true;
      settings = {
        version = "2"; # Required to set x-forward-for
        bindaddress = "127.0.0.1:9001";
        ldapbindaddress = "127.0.0.1:636";
        origin = "https://auth.macdermid.ca";
        domain = "auth.macdermid.ca";
        # log_level = "debug";
        tls_chain = config.sops.secrets.kanidm-tls-chain.path;
        tls_key = config.sops.secrets.kanidm-tls-key.path;
        http_client_address_info.x-forward-for = ["127.0.0.1"];
      };
    };
    client = {
      enable = true;
      settings = {
        uri = "${config.services.kanidm.server.settings.origin}";
      };
    };
  };
  services.n8n = {
    enable = true;
  };
  services.nordvpn-namespaced = {
    enable = true;
    namespaces = {
      romania = {
        remote = "89.46.103.171";
        verify-x509-name = "ro67.nordvpn.com";
      };
    };
  };
  services.nzbget.enable = true;
  systemd.services.nzbget.path = with pkgs; [
    unrar
    uv
    p7zip
    (python3.withPackages (python-pkgs: [
      local.pynzbget
      python-pkgs.apprise
    ]))
  ];
  services.mongodb = {
    enable = true;
    package = local.mongodb-bin_7;
    # Oddly the auth/initialRootPassword didn't work
    pidFile = "/run/mongodb/mongodb.pid";
    extraConfig = ''
      net:
        unixDomainSocket:
          enabled: true
          filePermissions: 0777
          pathPrefix: "/run/mongodb"

      security.authorization: enabled
      setParameter:
        authenticationMechanisms: SCRAM-SHA-256
    '';
  };
  systemd.services.mongodb.serviceConfig = {
    RuntimeDirectory = "mongodb";

    # https://www.mongodb.com/docs/manual/reference/ulimit
    LimitFSIZE = "infinity";
    LimitCPU = "infinity";
    LimitAS = "infinity";
    LimitMEMLOCK = "infinity";
    LimitNOFILE = 64000;
    LimitNPROC = 64000;
  };
  services.openssh = {
    enable = true;
    openFirewall = true;
    extraConfig = ''
      PrintLastLog no

      Match User media
        ChrootDirectory /srv/media

        AllowAgentForwarding no
        AllowTcpForwarding no
        X11Forwarding no

        ForceCommand internal-sftp
    '';
    settings.PasswordAuthentication = true;
  };
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    # Vector Extension
    extensions = ps:
      with ps; [
        pgvector
        vectorchord
      ];
    settings.shared_preload_libraries = [
      "vchord"
      "vector"
    ];
    # CREATE EXTENSION IF NOT EXISTS vector;
    # CREATE EXTENSION IF NOT EXISTS vchord;

    authentication = ''
      local all all ident map=mapping
    '';
    identMap = ''
      mapping kenny    postgres
      mapping root     postgres
      mapping postgres postgres
      mapping /^(.*)$  \1
    '';
  };

  ########################################
  # Immich
  ########################################
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    mediaLocation = "/srv/immich";
    accelerationDevices = ["/dev/dri/renderD128"];

    machine-learning.enable = true;
  };
  # Pin immich to uid/gid 911 (consistent with yoga) and grant GPU access.
  users.users.immich = {
    uid = config.ids.uids.immich;
    extraGroups = ["render" "video"];
  };
  users.groups.immich.gid = config.ids.gids.immich;

  # Expose Immich privately on the tailnet over HTTPS, mirroring r1pro's other
  # tailscale-serve-* services.
  systemd.services.tailscale-serve-immich = {
    description = "Tailscale serve Immich";
    wantedBy = ["multi-user.target"];
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    serviceConfig = {
      RestartSec = 10;
      Restart = "on-failure";
      ExecStartPre = "${lib.getExe waitTailscale}";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --service=svc:immich --https=443 127.0.0.1:2283";
    };
  };

  ########################################
  # Backups (restic -> /mnt/red USB drive)
  ########################################
  # Dump every postgres DB (immich, miniflux, kanidm, ...) to
  # /var/backup/postgresql/<db>.sql.gz nightly at 01:00 (module default; one
  # file per DB, overwritten each run -- restic snapshots provide history).
  services.postgresqlBackup.enable = true;

  # Immich media: originals + encoded-video + thumbs + profiles, all of /srv/immich.
  # Runs as root so it can read the 0700 immich-owned tree and write to /mnt/red.
  services.restic.backups.immich = {
    initialize = false;
    repository = "/mnt/red/immich-restic";
    passwordFile = config.sops.secrets.restic-immich.path;
    paths = ["/srv/immich"];
    # Going to put the backups on their own subvolume and snapshot so manually
    # prune when required.
    # pruneOpts = [
    #   "--keep-daily 7"
    #   "--keep-weekly 5"
    #   "--keep-monthly 12"
    #   "--keep-yearly 10"
    # ];
    timerConfig = {
      OnCalendar = "04:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  # Postgres dumps from services.postgresqlBackup (covers the immich DB + all
  # others). Runs after the 01:00 dump completes.
  services.restic.backups.postgresql = {
    initialize = false;
    repository = "/mnt/red/restic-postgresql";
    passwordFile = config.sops.secrets.restic-postgresql.path;
    paths = ["/var/backup/postgresql"];
    # pruneOpts = [
    #   "--keep-daily 7"
    #   "--keep-weekly 5"
    #   "--keep-monthly 12"
    #   "--keep-yearly 10"
    # ];
    timerConfig = {
      OnCalendar = "03:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  services.qbittorrent = {
    enable = true;
    group = "media";
    webuiPort = 59933;
  };
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "${config.networking.hostName}";
        "netbios name" = "${config.networking.hostName}";
        "security" = "user";
        "hosts allow" = "192.168.2. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      media = {
        path = "/srv/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "guest only" = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = config.users.users.media.name;
        "force group" = config.users.groups.media.name;
      };
    };
  };
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  services.zerotier-home.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.bigagi = {
    image = "localhost/bigagi:stable";
    environmentFiles = [config.sops.secrets.bigagi.path];
    ports = ["127.0.0.1:3000:3000"];
  };
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      dns_enabled = true;
      # Use /24 with 100-200 for dynamic
      subnets = [
        {
          subnet = "10.88.0.0/24";
          gateway = "10.88.0.1";
          lease_range = {
            start_ip = "10.88.0.100";
            end_ip = "10.88.0.200";
          };
        }
      ];
    };
  };
  zramSwap.enable = true;

  ########################################
  # User
  ########################################
  users.motd = ''
    Welcome to r1pro. This system is running NixOS.

    To find a package:
    $ nix search nixpkgs ___
    or use https://search.nixos.org/packages

    To install a package:
    $ nix shell nixpkgs#___
  '';

  users.groups.media.members = with config.users.users; [
    config.services.jellyfin.user
    config.services.nzbget.user

    kenny.name
    media.name
  ];

  users.users.media = {
    uid = config.ids.uids.media;
    home = "/srv/media";
    homeMode = "2770";
    isNormalUser = true;
    shell = pkgs.shadow;
    group = "media";
  };

  users.users.sftp-yoga = {
    uid = config.ids.uids.sftp-yoga;
    sftpOnly = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJ0iluA6vWgJ0cBfwLLYLozRJ4r7UBxkPYzOWWqYcf/"
    ];
  };

  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    alejandra
    bcachefs-tools
    btrfs-progs
    dhcpcd
    git
    gitui
    gnumake
    fd
    fwupd
    htop
    kitty # for term info only
    libva-utils
    mongosh
    ncdu
    powertop
    pstree
    restic
    ripgrep
    tmux
  ];
  ########################################
  # nginx reverse proxy (LAN-only) for *.home.macdermid.ca
  ########################################
  systemd.services.nginx.serviceConfig.SupplementaryGroups = ["acme"];
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "kenny@macdermid.ca";
      dnsProvider = "cloudflare";
      credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare.path;
      dnsResolver = "1.1.1.1:53";
    };
    certs."home.macdermid.ca" = {
      domain = "*.home.macdermid.ca";
      extraDomainNames = ["home.macdermid.ca"];
      reloadServices = ["nginx"];
    };
  };
  services.nginx = {
    enable = true;
    serverTokens = false;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    sslProtocols = "TLSv1.3";
    clientMaxBodySize = "10g"; # immich video uploads
    commonHttpConfig = ''
      geo $internal {
        default no;
        127.0.0.0/8 yes;
        172.27.0.0/24 yes; # LAN
        100.64.0.0/10 yes; # Tailscale CGNAT
        10.88.0.0/16 yes;  # podman
      }
    '';
    virtualHosts = let
      # LAN-only TLS vhost behind the *.home.macdermid.ca wildcard cert, gated by
      # the `internal` geo-map (404 to anyone off the LAN/tailnet). Add a service
      # with:  "<svc>.home.macdermid.ca" = proxywss <port>;
      proxywss = port: {
        onlySSL = true;
        useACMEHost = "home.macdermid.ca";
        http2 = true;
        extraConfig = ''
          if ($internal != yes) {
            return 404;
          }
        '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };
    in {
      "jellyfin.home.macdermid.ca" = proxywss 8096;
    };
  };
}
