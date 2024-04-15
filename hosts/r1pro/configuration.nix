{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./networkd.nix
  ];

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
  services.fwupd.enable = true;
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
  services.jellyfin.enable = true;
  systemd.services.jellyfin.serviceConfig = {
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
  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "3efa5cb78a1548d5" # Home
    ];
  };

  systemd.services.zerotierone.serviceConfig = {
    KillMode = lib.mkForce "control-group";
    TimeoutStopFailureMode = "kill";
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

    kenny.name
    media.name
  ];

  users.users.media = {
    uid = 1001;
    isNormalUser = true;
    shell = "${pkgs.shadow}/bin/nologin";
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
    nixfmt
    powertop
    pstree
    tmux
  ];
}
