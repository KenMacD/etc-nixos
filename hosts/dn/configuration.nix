{ config, lib, pkgs, nixpkgs, ... }: {
  imports = [
    ./audio.nix
#    ./larger-coredumps.nix
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
  services.hardware.bolt.enable = true;
  # Force intel vulkan driver to prevent software rendering:
  environment.variables.VK_ICD_FILENAMES =
    "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";

  boot.kernelPackages = pkgs.linuxPackages_zen;
  # Set ZFS to keep 3G free, otherwise firefox unloads tabs
  # too frequently. Re-examine when/if issue fixed.
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_sys_free=3221225472
  '';
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
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
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
      "lxd"
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
  virtualisation = {
    docker.enable = true;
    lxc = {
      enable = true;
      lxcfs.enable = true;
    };
    lxd.enable = true;
    waydroid.enable = true;
  };

  ########################################
  # Security
  ########################################

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

      # System performance
      htop
      stress-ng
      s-tui

      # Terminal related
      kitty
      mdcat

      # Password management
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
      (weechat.override {
        configure = { availablePlugins, ... }: {
          plugins = with availablePlugins; [ python ];
          scripts = with pkgs.weechatScripts; [
            (wee-slack.overrideAttrs (oldAttrs: rec {
              version = "2.7.0";
              src = fetchFromGitHub {
                repo = "wee-slack";
                owner = "KenMacD";
                rev = "bed1747daeca0151d3b5d1543f8e2529b4e423e8";
                sha256 = "19aizpn1qfar05jqgx2kmjjwml6a8gnhi570fxyqc1zpcy12wjqk";
              };
            }))
          ];
        };
      })

      # Email
      fdm  # fetch mail from imap
      msmtp  # simple smtp clipent
      neomutt
      notmuch  # search
      pdfminer # pdf
      python3Packages.icalendar  # ical view
      khal  # ical view
      urlscan
      urlview
      lynx
      #maildrop  # for making Maildir and folders

      # Android
      abootimg
      brotli
      dtc
      heimdall
      meson-tools

      # Unsorted
      delta
      most
      mindforger
      ffmpeg
      binwalk
      screen
      qalculate-gtk
      mitmproxy

      # Games

      # General/Unsorted
      magic-wormhole
      patchelf
      sshfs

      # Virtualization
      virt-manager
      lxd
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
      fre
    ];
}
