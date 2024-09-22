{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./lobechat.nix
    ./networkd.nix
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

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
        intel-media-sdk
      ];
    };
  };

  ########################################
  # Secrets
  ########################################
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.cloudflare-tunnel = {
    owner = config.services.cloudflared.user;
    inherit (config.services.cloudflared) group;
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
  # TODO: set
  networking.firewall.enable = false;
  networking = {
    hostName = "r1pro";
    useNetworkd = true;
    # wireless.enable = false;
    networkmanager.enable = false;
    #domain = "home.macdermid.ca";
    # TODO: set?
    #hostId = "f5a3f353";
  };

  ########################################
  # Services
  ########################################
  system.autoUpgrade = {
    enable = true;
    flake = "path:/home/kenny/src/nixos#r1pro";
    flags = [
      "--recreate-lock-file"
      "-L" # print build logs
    ];
    dates = "03:30";
    randomizedDelaySec = "45min";
  };
  services.caddy = {
    enable = true;
    globalConfig = ''
      cert_issuer acme {
        disable_http_challenge
      }
    '';
    extraConfig = ''
      (common) {
        header /* {
          -Server
        }
      }
    '';
    virtualHosts."jellyfin.macdermid.ca" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8096
        import common
      '';
    };
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
  services.fwupd.enable = true;
  services.jellyfin.enable = true;
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
    python39 # TODO: when videosort updated, update python
  ];
  services.openssh = {
    enable = true;
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
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    # https://docs.pgvecto.rs/admin/upgrading.html
    # CREATE EXTENSION IF NOT EXISTS vectors;
    extraPlugins = with pkgs.postgresql.pkgs; [pgvecto-rs];
    settings = {shared_preload_libraries = "vectors";};
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
  services.zerotier-home = {
    enable = true;
    zeronsd.enable = true;
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
    uid = 1001;
    isNormalUser = true;
    shell = pkgs.shadow;
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
    libva-utils
    ncdu
    powertop
    pstree
    tmux
  ];
}
