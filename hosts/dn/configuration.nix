{
  config,
  lib,
  pkgs,
  nixpkgs,
  inputs,
  system,
  ...
}: {
  imports = [
    ./android.nix
    ./audio.nix
    ./bwrap.nix
    ../../modules/hp-printer.nix
    ./firewall.nix
    ./re.nix
    ./rust.nix
    ./sboot.nix
    ./virt.nix
    ./vscode.nix

    ./networkd.nix
    ./spectrum.nix
    ./work.nix
  ];

  ########################################
  # Nix
  ########################################
  nix.settings = {
    sandbox = true;
    substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
  };
  nix.settings.trusted-users = ["root" "kenny"];
  nix.extraOptions = ''
    binary-caches-parallel-connections = 12
    warn-dirty = false
    experimental-features = ca-derivations

    extra-experimental-features = auto-allocate-uids
    auto-allocate-uids = true

    extra-experimental-features = cgroups
    use-cgroups = true
  '';

  nixpkgs.config = {};

  # Allow edit of /etc/host for temporary mitm:
  environment.etc.hosts.mode = "0644";
  environment.enableDebugInfo = true;

  ########################################
  # Hardware
  ########################################
  hardware = {
    enableRedistributableFirmware = true;
    opengl = {
      enable = true;
      driSupport = true; # for vulkan
      driSupport32Bit = true;
      setLdLibraryPath = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
        pipewire
      ];
      extraPackages = with pkgs; [
        intel-compute-runtime
        # LIBVA_DRIVER_NAME=iHD (newer)
        intel-media-driver
        vaapiVdpau
      ];
    };
  };
  services.hardware.bolt.enable = true;
  services.avahi.enable = true; # For Chromecast
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Force intel vulkan driver to prevent software rendering:
  environment.variables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";
  environment.variables.LIBVA_DRIVER_NAME = "iHD";

  boot.kernel.sysctl = {"dev.i915.perf_stream_paranoid" = 0;};
  boot.extraModulePackages = with config.boot.kernelPackages; [
    turbostat
    x86_energy_perf_policy
  ];

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=CA
  '';

  # reboot + signals + sync
  boot.kernel.sysctl = {"kernel.sysrq" = 128 + 64 + 16;};

  ########################################
  # Network
  ########################################
  networking = {
    hostName = "dn";
    hostId = "822380ad";
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;

  services.resolved = {
    enable = true;
  };

  # Make resolv.conf a direct symlink
  # Workaround https://github.com/NixOS/nixpkgs/issues/231191
  environment.etc."resolv.conf".mode = "direct-symlink";


  ########################################
  # Desktop Environment
  ########################################
  boot.kernelParams = ["console=tty2"];
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --cmd ${pkgs.sway}/bin/sway";
        user = "greeter";
      };
    };
  };
  programs.xwayland.enable = false;

  # Use Wayland for Electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.pathsToLink = ["/libexec"]; # Required for sway/polkit
  environment.shellAliases = {
    "ls" = "lsd";
    "ta" = "task add rc.context=none";
  };
  programs.sway-desktop.enable = true;
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # Install gui pkg
  };
  gtk.iconCache.enable = true;
  xdg.icons.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  qt.platformTheme = "qt5ct";

  ########################################
  # Services
  ########################################
  services = {
    flatpak.enable = true;
    fwupd.enable = true;
    lorri.enable = true;
    openssh.enable = false;
    pcscd.enable = true;
    snapper.configs.home = {
      ALLOW_USERS = ["kenny"];
      SUBVOLUME = "/home";
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
    };
    thermald.enable = true;
    udev = {
      packages = [pkgs.yubikey-personalization];
      # Amlogic:
      extraRules = ''
        SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1b8e", ATTR{idProduct}=="c003", MODE:="0666", SYMLINK+="worldcup"
      '';
    };
    udisks2.enable = true;
    ddccontrol.enable = true;
    zerotier-home = {
      enable = true;
      zeronsd = {
        enable = true;
        package = pkgs.zeronsd;
      };
    };
  };

  zramSwap.enable = true;

  services.wpantund = {
    enable = true;
    # TODO: udev rule to a different device name
    socketPath = "/dev/ttyACM0";
  };

  ########################################
  # Fonts
  ########################################
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override {
        fonts = [
          "NerdFontsSymbolsOnly"
        ];
      })
      dosis
      fira-code
      fira-code-symbols
      font-awesome # Used by waybar
      roboto
      roboto-mono
    ];
    fontconfig = {defaultFonts = {monospace = ["Fira Code"];};};
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
    Defaults  env_keep += "RESTIC_PASSWORD"
    Defaults  env_keep += "RESTIC_PASSWORD_COMMAND"
    Defaults  env_keep += "RESTIC_PASSWORD_FILE"
    Defaults  env_keep += "RESTIC_REPOSITORY"
  '';
  security.pam.services = {
    # login.u2fAuth = true;
    sudo.u2fAuth = true;
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
  # Security
  ########################################
  security.tpm2 = {
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
    enable = true;
  };

  ########################################
  # Packages
  ########################################
  nixpkgs.overlays = [];
  programs.bcc.enable = true;
  # broken 2023-02-21 & 2023-05-25 programs.sysdig.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      gcloud.disabled = true;
      nix_shell.disabled = true;
      git_status = {
        style = "purple bold dimmed";
        stashed = "";
        modified = "";
        untracked = "";
        staged = "✓$count";
        renamed = "🚚$count";
        deleted = "✗$count";
        ahead = "⇡$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        behind = "⇣$count";
      };
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    package = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          libgdiplus
          glib
        ];
      extraProfile = ''
        export GSETTINGS_SCHEMA_DIR="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/"
      '';
    };
  };

  programs.thefuck.enable = true;
  environment.systemPackages = with pkgs;
  with config.boot.kernelPackages; [
    # General
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    bc
    brightnessctl
    chromium
    fd
    firefox
    fzf
    httpie
    libreoffice-fresh
    immich-go  # local
    libreoffice
    librewolf
    libusb1
    libva-utils
    magic-wormhole
    (nnn.override {withNerdIcons = true;})
    p7zip
    patchelf
    python3
    restic
    ratarmount  # Mount tar/archives with FUSE
    rlwrap
    rmlint
    tmux
    sshfs
    unzip
    xdg-utils
    yt-dlp

    # System performance
    glances
    htop
    stress-ng
    s-tui

    # Terminal related
    kitty
    lsd # ls, but better
    mdcat
    most
    vivid # for LS_COLORS
    yq-go # Using to switch color theme

    # Password management
    age-plugin-yubikey
    gopass # replacement for pass, has -o option
    gopass-jsonapi
    qtpass
    rage
    yubikey-manager
    yubikey-personalization
    yubioath-flutter

    # Video
    intel-gpu-tools
    mpv
    v4l-utils
    vlc

    # Graphics
    glxinfo
    mesa_glu

    # System management
    acpid
    bcc
    compsize  # Show on-disk file size
    dig
    fwupd
    fwupd-efi
    iotop
    kanidm
    killall
    lxqt.lxqt-policykit
    ncdu # disk usage with file count
    nvme-cli
    pciutils
    powertop
    power-profiles-daemon
    pstree
    remmina
    usbutils
    turbostat
    x86_energy_perf_policy

    # Networking
    _3proxy
    openconnect

    # Nix
    alejandra # Nix formatter
    nix-tree
    nixfmt
    nixpkgs-fmt

    # Wireless
    aircrack-ng

    # Communication
    discord
    irssi
    signal-desktop
    slack
    (weechat.override {
      configure = {availablePlugins, ...}: {
        plugins = with availablePlugins; [python];
        scripts = with pkgs.weechatScripts; [
          buffer_autoset
          wee-slack
          weechat-autosort
          weechat-go
        ];
      };
    })

    # Email
    fdm # fetch mail from imap
    msmtp # simple smtp client
    neomutt
    notmuch # search
    pdfminer # pdf
    python3Packages.icalendar # ical view
    khal # ical view
    ripmime # pipe msgs to extract attachements
    urlscan
    lynx

    # Task management
    taskwarrior
    taskwarrior-tui
    taskopen
    vit

    # General/Unsorted
    # Virtualization
    virt-manager
    nixos-generators
    bubblewrap

    # Version Control related
    # gitFull
    git-absorb # git commit --fixup, but automatic
    git-no-hooks
    git-filter-repo
    git-lfs
    gita  # Update a group of repos
    gitui
    jujutsu  # jj command for git, to try out

    # Development
    amazon-ecs-cli
    android-tools
    aws-adfs
    awscli2
    aws-azure-login
    bintools
    binwalk
    clang-tools
    delta
    direnv
    dtc
    file
    gdb
    gh
    gnumake
    hotspot
    insomnium # Postman like API tool
    jq
    llvm
    man-pages
    meld
    meson-tools
    mold
    nix-bubblewrap
    nix-direnv
    parallel
    perf
    pkgconf
    pgcli
    ripgrep
    tio

    # My Packages
    fre
    modprobed-db
  ];
}
