{
  self,
  config,
  pkgs,
  lib,
  system,
  ...
}: let
  local = self.packages.${system};
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
        vaapiVdpau
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
  sops.secrets.bigagi = {};

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
    allowedTCPPorts = [];
    allowedUDPPorts = [
      5353 # mDNS
      5355 # LLMNR (Link-Local Multicast Name Resolution)
    ];
  };

  ########################################
  # Services
  ########################################
  system.autoUpgrade = {
    enable = true;
    flake = "path:/etc/nixos#r1pro";
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
      JELLYFIN_PublishedServerUrl = "https://jellyfin.macdermid.ca";
    };
    serviceConfig = {
      CapabilityBoundingSet = "";
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectHome = true;
      ProtectSystem = "strict";
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
  services.nzbget.enable = true;
  systemd.services.nzbget.path = with pkgs; [
    unrar
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
    enableTCPIP = false;
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
    ports = ["3000:3000"];
  };
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      dns_enabled = true;
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
}
