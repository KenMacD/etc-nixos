{ config, lib, pkgs, nixpkgs, ... }: {
  imports = [
    ./audio.nix
    ./virt.nix
#    ./larger-coredumps.nix
  ];

  ########################################
  # Nix
  ########################################
  nix.settings = {
    sandbox = true;
    substituters = [ "https://aseipp-nix-cache.global.ssl.fastly.net" ];
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
    enableAllFirmware = true;
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
  boot.extraModulePackages = with config.boot.kernelPackages; [
    intel-speed-select
    turbostat
    x86_energy_perf_policy
  ];
  boot.extraModprobeConfig = ''
  '';

  boot.kernel.sysctl = { "kernel.sysrq" = 1; };

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

  services.resolved.enable = false;

  ########################################
  # Desktop Environment
  ########################################
  programs.xwayland.enable = false;
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      cmst
      grim # screenshot
      libinput
      mako # notifications (tiramisu?)
      papirus-icon-theme
      slurp # select area for screenshot
      swayidle
      swaylock
      waybar
      wl-clipboard
      wofi
      xwayland
      wdisplays
      networkmanagerapplet

      # Screensharing
      xdg-desktop-portal-wlr

      glfw-wayland
      glew
      qt5.qtwayland

      polkit-kde-agent

      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
      gnome3.adwaita-icon-theme

      # Display profiles
      kanshi
    ];
    extraSessionCommands = ''
      export SDL_VIDEODRIVER="wayland"
      export QT_QPA_PLATFORM="wayland"
      export QT_WAYLAND_DISABLE_WINDOWDECORATIONS="1"
      export _JAVA_AWT_WM_NONREPARENTING="1"
    '';
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
  };
  # Use Wayland for Electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.pathsToLink = [ "/libexec" ]; # Required for sway/polkit
  environment.shellAliases = { "ls" = "lsd"; };
  programs.waybar.enable = true;
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # Install gui pkg
  };
  gtk.iconCache.enable = true;
  xdg.icons.enable = true;
  xdg.portal.wlr.enable = true; # Screensharing
  qt5.platformTheme = "qt5ct";

  ########################################
  # Services
  ########################################
  services = {
    fwupd.enable = true;
    openssh.enable = false;
    pcscd.enable = true;
    udev = {
      packages = [ pkgs.yubikey-personalization ];
      # Amlogic:
      extraRules = ''
        SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1b8e", ATTR{idProduct}=="c003", MODE:="0666", SYMLINK+="worldcup"
      '';
    };
    zerotierone.enable = true;
  };

  zramSwap.enable = true;

  systemd.services.zerotierone.serviceConfig = {
    KillMode = lib.mkForce "control-group";
    TimeoutStopFailureMode = "kill";
  };

  services.wpantund = {
    enable = true;
    # TODO: udev rule to a different device name
    socketPath = "/dev/ttyACM0";
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
      "dialout"
      "libvirtd"
      "lxd"
      "networkmanager"
      "video"

      "scanner"
      "lp"

      config.security.wrappers.dumpcap.group
    ];
  };
  security.sudo.extraConfig = ''
    Defaults  env_keep += "DISPLAY"
  '';

  ########################################
  # Crypto
  ########################################
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ########################################
  # Security
  ########################################
  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
  };

  ########################################
  # Packages
  ########################################
  nixpkgs.overlays = [ ];
  programs.bcc.enable = true;
  programs.sysdig.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

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
      firefox-bin
      fzf
      httpie
      libreoffice
      libusb1
      libva-utils
      lsd # ls, but better
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
      gopass # replacement for pass, has -o option
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
          scripts = with pkgs.weechatScripts;
            [
              (wee-slack.overrideAttrs (oldAttrs: rec {
                version = "2.7.0";
                src = fetchFromGitHub {
                  repo = "wee-slack";
                  owner = "KenMacD";
                  rev = "bed1747daeca0151d3b5d1543f8e2529b4e423e8";
                  sha256 =
                    "19aizpn1qfar05jqgx2kmjjwml6a8gnhi570fxyqc1zpcy12wjqk";
                };
              }))
            ];
        };
      })

      # Email
      # fetch mail from imap
      # Override fdm because 2.0 version does not have XOAUTH2 support
      ((fdm.override { openssl = libressl; }).overrideAttrs (old: {
        version = "cf19f51f5b33c5a05fe41bd4a614063a9b706693";
        src = fetchFromGitHub {
          owner = "nicm";
          repo = "fdm";
          rev = "cf19f51f5b33c5a05fe41bd4a614063a9b706693";
          sha256 = "0x0ich0cl0h7y6zsg7s9agj0plgw976i1a4zrqz6kpbldfg1r63q";
        };
        configureFlags = (super.configureFlags or [ ])
          ++ [ "--with-tls=libtls" ];
      }))
      # simple smtp client
      ((msmtp.override { gnutls = null; }).overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ libressl ];
        configureFlags = (old.configureFlags or [ ]) ++ [ "--with-tls=libtls" ];
      }))
      neomutt
      notmuch # search
      pdfminer # pdf
      python3Packages.icalendar # ical view
      khal # ical view
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
      steam-run
      mindforger
      ffmpeg
      taskwarrior
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
