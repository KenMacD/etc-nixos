{ config, lib, pkgs, nixpkgs, ... }: {
  imports = [ ./android.nix ./audio.nix ./firewall.nix ./virt.nix ];

  ########################################
  # Nix
  ########################################
  nix.settings = {
    sandbox = true;
    substituters = [ "https://aseipp-nix-cache.global.ssl.fastly.net" ];
  };
  nix.settings.trusted-users = [ "root" "kenny" ];
  nix.extraOptions = ''
    binary-caches-parallel-connections = 12
    warn-dirty = false
    experimental-features = ca-derivations
  '';

  nixpkgs.config = { };

  # Allow edit of /etc/host for temporary mitm:
  environment.etc.hosts.mode = "0644";
  environment.enableDebugInfo = true;

  ########################################
  # Hardware
  ########################################
  hardware = {
    enableAllFirmware = true;
    opengl = {
      enable = true;
      driSupport = true; # for vulkan
      driSupport32Bit = true;
      setLdLibraryPath = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        # LIBVA_DRIVER_NAME=iHD (newer)
        intel-media-driver
        vaapiVdpau
      ];
    };
  };
  services.hardware.bolt.enable = true;
  services.avahi.enable = true;  # For Chromecast

  # Force intel vulkan driver to prevent software rendering:
  environment.variables.VK_ICD_FILENAMES =
    "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernel.sysctl = { "dev.i915.perf_stream_paranoid" = 0; };
  boot.extraModulePackages = with config.boot.kernelPackages; [
    turbostat
    x86_energy_perf_policy

    # Wifi - Alfa USB
    (rtl8812au.overrideAttrs (old: {
      version = "7de980d325ff7a40a67866bb6cf294f327e36fa2";
      src = pkgs.fetchFromGitHub {
        owner = "morrownr";
        repo = "8812au-20210629";
        rev = "7de980d325ff7a40a67866bb6cf294f327e36fa2";
        sha256 = "sha256-n2P++2cK/2f9hCjXqz99zDcxlKrv/pMXy+r6uNy+AFc=";
      };
      meta.broken = false;
    }))
    rtl8821au
  ];

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=CA
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
  services.tlp.enable = true;

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
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
    };
    fwupd.enable = true;
    lorri.enable = true;
    openssh.enable = false;
    pcscd.enable = true;
    thermald.enable = true;
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
      "networkmanager"
      "video"

      "scanner"
      "lp"

      config.security.wrappers.dumpcap.group
    ];
  };
  security.doas.enable = true;
  security.sudo.extraConfig = ''
    Defaults  env_keep += "DISPLAY"
    Defaults  env_keep += "PYTHONPATH"
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
      firefox
      fzf
      httpie
      libreoffice
      libusb1
      libva-utils
      lsd # ls, but better
      most
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
      fdm
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

      steam-run
      mindforger
      ffmpeg
      taskwarrior
      binwalk
      screen
      qalculate-gtk
      mitmproxy

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
      delta
      direnv
      dtc
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
      meson-tools
      mold
      nix-direnv
      parallel
      perf
      pkgconf
      stable.pgcli
      ripgrep
      rustup
      tio
      vscodium-fhs # TODO: build with extensions

      # My Packages
      fre
    ];
}
