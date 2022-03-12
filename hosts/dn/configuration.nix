{ config, lib, pkgs, nixpkgs, ... }: {
  imports = [
    ./audio.nix
#    ./larger-coredumps.nix
#    ./sway-dbg.nix
  ];

  ########################################
  # Nix
  ########################################
  nix.settings = {
    sandbox = true;
    substituters = [
      "https://aseipp-nix-cache.global.ssl.fastly.net"
    ];
  };

  nixpkgs.config = {
    packageOverrides = pkgs: {
      gnupg = pkgs.gnupg.override { libusb1 = pkgs.libusb1; };

      # Allow unstable.PackageName
      unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
    };
  };

  # Allow edit of /etc/host for temporary mitm:
  environment.etc.hosts.mode = "0644";

  ########################################
  # Hardware
  ########################################
  hardware = {
    firmware = with pkgs; [ wireless-regdb ];
    opengl = {
      enable = true;
      driSupport = true; # for vulkan
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        # LIBVA_DRIVER_NAME=iHD (newer)
        intel-media-driver
        vaapiVdpau
      ];
    };
  };
  # Force intel vulkan driver to prevent software rendering:
  environment.variables.VK_ICD_FILENAMES =
    "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";

  boot.kernelPackages = pkgs.linuxPackages_xanmod;
  boot.zfs.enableUnstable = true;
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
  };

  ########################################
  # ZFS
  ########################################
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoSnapshot.enable = true;

  ########################################
  # Network
  ########################################
  networking = {
    hostName = "dn";
    hostId = "822380ad";
    useNetworkd = true;
    networkmanager = {
      enable = true;
      connectionConfig = { "connection.llmnr" = 0; };
    };
    wireless.enable = false;
  };
  systemd.services."systemd-networkd-wait-online".enable = false;
  services.unbound.enable = true;
  services.resolved.enable = false;

  ########################################
  # Desktop Environment
  ########################################
  programs.qt5ct.enable = true;
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      grim # screenshot
      libinput
      networkmanagerapplet
      papirus-icon-theme
      slurp # select area for screenshot
      swayidle
      swaylock
      waybar
      wl-clipboard
      wofi
      xwayland
      wdisplays

      polkit-kde-agent

      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
      gnome3.adwaita-icon-theme
    ];
  };
  environment.pathsToLink = [ "/libexec" ];  # Required for sway/polkit
  programs.waybar.enable = true;
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;  # Install gui pkg
  };
  xdg.icons.enable = true;

  ########################################
  # Services
  ########################################
  services = {
    fwupd.enable = true;
    openssh.enable = false;
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
    zerotierone.enable = true;
  };

  systemd.services.zerotierone.serviceConfig = {
    KillMode = lib.mkForce "control-group";
    TimeoutStopFailureMode = "kill";
  };

  ########################################
  # Fonts
  ########################################
  fonts = {
    fonts = with pkgs; [
      fira-code
      font-awesome # Used by waybar
    ];
    fontconfig = { defaultFonts = { monospace = [ "Fira Code" ]; }; };
  };

  ########################################
  # User
  ########################################
  users.users.kenny = {
    extraGroups = [
      "docker"
      "libvirtd"
      "networkmanager"
      "dialout"
      config.security.wrappers.dumpcap.group
    ];
  };

  ########################################
  # Crypto
  ########################################
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ########################################
  # Containers
  ########################################
  virtualisation.docker = {
    enable = true;
  };

  ########################################
  # Security
  ########################################
  programs.firejail = {
    enable = true;
    wrappedBinaries = { teams = "${pkgs.lib.getBin pkgs.teams}/bin/teams"; };
  };

  ########################################
  # Packages
  ########################################
  programs.steam.enable = true;
  services.lorri.enable = true;

  environment.systemPackages = with pkgs;
    with config.boot.kernelPackages; [
      # General
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      bc
      borgbackup
      brightnessctl
      chromium
      fd
      firefox-wayland
      fzf
      htop
      httpie
      libreoffice
      libusb1
      libva-utils
      lsd  # ls, but better
      p7zip
      python3
      python3Packages.poetry
      rlwrap
      tmux
      unzip
      xdg-utils
      yt-dlp

      # Terminal related
      kitty
      mdcat

      # Password management
      (pass.override {
        x11Support = false;
        waylandSupport = true;
      })
      gopass  # replacement for pass, has -o option
      gopass-jsonapi
      qtpass
      yubikey-manager
      yubikey-personalization
      yubioath-desktop

      # Video
      intel-gpu-tools
      mpv
      v4l_utils
      vlc

      # Graphics
      glxinfo
      mesa_glu

      # System management
      acpid
      bcc
      dig
      fwupd
      fwupd-efi
      intel-speed-select
      iotop
      killall
      lxqt.lxqt-policykit
      ncdu # disk usage with file count
      nvme-cli
      pciutils
      powertop
      power-profiles-daemon
      pstree
      usbutils
      turbostat
      x86_energy_perf_policy

      # Networking
      openconnect

      # Nix
      nixfmt
      nixpkgs-fmt

      # Wireless
      iw
      wavemon
      wirelesstools
      aircrack-ng

      # Communication
      discord
      irssi
      signal-desktop
      slack
      # teams -- Included in firejail
      (weechat.override {
        configure = { availablePlugins, ... }: {
          plugins = with availablePlugins; [ python ];
          scripts = with pkgs.weechatScripts; [
            weechat-matrix
            (wee-slack.overrideAttrs (oldAttrs: rec {
              version = "2.7.0";
              src = fetchFromGitHub {
                repo = "wee-slack";
                owner = "KenMacD";
                rev = "bed1747daeca0151d3b5d1543f8e2529b4e423e8";
                sha256 = "19aizpn1qfar05jqgx2kmjjwml6a8gnhi570fxyqc1zpcy12wjqk";
              };
            }))
            weechat-autosort
            weechat-notify-send
          ];
          extraBuildInputs = [
            availablePlugins.python.withPackages
            (_: [ pkgs.weechat-matrix ])
          ];
        };
      })

      # Email
      fdm  # fetch mail from imap
      msmtp  # simple smtp clipent
      neomutt
      notmuch  # search
      python3Packages.icalendar  # ical view
      urlscan
      urlview
      lynx
      #maildrop  # for making Maildir and folders

      # Android
      abootimg
      brotli

      # Games

      # General/Unsorted
      magic-wormhole
      patchelf
      sshfs

      # Virtualization
      docker
      docker-compose
      nixos-generators
      bubblewrap

      # Development
      amazon-ecs-cli
      android-tools
      aws-adfs
      awscli2
      bintools
      clang
      direnv
      file
      gdb
      gh
      gitFull
      github-desktop
      gnumake
      hotspot
      jq
      llvm
      man-pages
      mold
      nix-direnv
      parallel
      perf
      pgcli
      ripgrep
      rustup
      tio
      vscodium-fhs # TODO: build with extensions

      # My Packages
      (rustPlatform.buildRustPackage rec {
        pname = "fre";
        version = "0.3.1";

        src = fetchFromGitHub {
          owner = "camdencheek";
          repo = pname;
          rev = version;
          sha256 = "0j7cdvdc1007gs1kixk36y2zlgrkixqiaqvnkwd0pk56r4pbwvcw";
        };

        cargoSha256 = "0zb1x1qm4pw7hmkljsnrd233qzmk24c5v6x3q2dsfc5rp9xicjyb";

        meta = with lib; {
          description = "Command line frecency tracking";
          homepage = "https://github.com/camdencheek/fre/";
          license = licenses.mit;
          maintainers = [ ];
        };
      })
    ];
}
