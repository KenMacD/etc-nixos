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
    ./emacs.nix
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
  # Secrets
  ########################################
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.restic-efi = {};

  ########################################
  # Nix
  ########################################
  # nix.package = pkgs.nixVersions.unstable;
  nix.settings = {
    sandbox = true;
    substituters = [
      #      "https://nix.home.macdermid.ca"
      #      "https://nix.macdermid.ca"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
    ];
    trusted-public-keys = [
      "nix.home.macdermid.ca:CQuA65gXW8KuFlk9Ufx5oMsAiTZzQhfluNoaOzypXMo="
      "nix.macdermid.ca:sAlwW/Ph4P8pyrUT7pmWnsFeGVyZ7pyXYjUmo41/hc8="
    ];
  };
  nix.extraOptions = ''
    binary-caches-parallel-connections = 12
    warn-dirty = false
    experimental-features = ca-derivations

    extra-experimental-features = auto-allocate-uids
    auto-allocate-uids = true

    extra-experimental-features = cgroups
    use-cgroups = true
  '';
  # When building mongodb enable the following. Otherwise it takes
  # forever just to run out of space
  # see: https://github.com/NixOS/nixpkgs/issues/54707#issuecomment-1132907191
  # systemd.services.nix-daemon = { environment.TMPDIR = "/nix/tmp"; };
  # systemd.tmpfiles.rules = [ "d /nix/tmp 0755 root root 1d" ];

  nixpkgs.config = {};

  # Allow edit of /etc/host for temporary mitm:
  environment.etc.hosts.mode = "0644";
  environment.enableDebugInfo = true;

  ########################################
  # Hardware
  ########################################
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        vaapiVdpau
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
        pipewire
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

  boot.kernelParams = [
    # "nohz_full=1-7"
    "preempt=full"
    "nmi_watchdog=0"
    "vm.dirty_writeback_centisecs=6000"

    # TODO: move to common? or maybe just desktop?
    "panic=0"

    # "i915.enable_dc=1"
    # "i915.edp_vswing=0"
    # "i915.enable_guc=2"
    # "i915.enable_fbc=1"
    # "i915.enable_psr=1"
    # "i915.disable_power_well=0"
  ];
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
    hostName = "ke";
    hostId = "65350c54";
    useNetworkd = true;
    networkmanager.enable = false;
  };
  home-wifi.enable = true;

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;

  services.resolved = {
    enable = true;
  };

  # Make resolv.conf a direct symlink
  # Workaround https://github.com/NixOS/nixpkgs/issues/231191
  environment.etc."resolv.conf".mode = "direct-symlink";

  environment.etc = {
    "nixos-overlays/overlays.nix" = {
      mode = "0444";
      text = ''
        self: super:
        with super.lib;
        let
          # Load the system config and get the `nixpkgs.overlays` option
          overlays = (import <nixpkgs/nixos> { }).config.nixpkgs.overlays;
        in
          # Apply all overlays to the input of the current "main" overlay
          foldl' (flip extends) (_: super) overlays self
      '';
    };
  };

  ########################################
  # Desktop Environment
  ########################################
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

  #  programs.hyprland = {
  #    enable = true;
  #    xwayland.enable = true;
  #  };

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
    # May be needed: https://wiki.archlinux.org/title/XDG_Desktop_Portal#Poor_font_rendering_in_GTK_apps_on_KDE_Plasma
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
  qt.platformTheme = "qt5ct";

  ########################################
  # Services
  ########################################
  services = {
    flatpak.enable = true;
    fprintd = {
      enable = true;
      tod.enable = true;
      tod.driver = pkgs.libfprint-2-tod1-goodix;
    };
    fwupd.enable = true;
    lorri.enable = true;
    openssh.enable = true;
    pcscd.enable = true;
    restic.backups.efi = {
      repository = "/root/restic-efi";
      passwordFile = config.sops.secrets.restic-efi.path;
      paths = [
        "/boot"
      ];
      timerConfig = {
        OnCalendar = "daily";
      };
    };
#    snapper.configs.home = {
#      ALLOW_USERS = ["kenny"];
#      SUBVOLUME = "/home";
#      TIMELINE_CREATE = true;
#      TIMELINE_CLEANUP = true;
#    };
    thermald.enable = true;
    udev = {
      packages = [
        pkgs.yubikey-personalization
        pkgs.espanso-wayland
      ];

      # Amlogic:
      # particle usb flash dongle
      # if systemd-logind use uaccess
      extraRules = ''
        SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1b8e", ATTR{idProduct}=="c003", MODE:="0666", SYMLINK+="worldcup", OWNER="kenny", GROUP="users"
        ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", OWNER="kenny", GROUP="users"

        SUBSYSTEM=="usb", ATTR{idVendor}=="05ed", TEST=="power/control", ATTR{power/control}="on"

        SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="3000", OWNER="kenny", GROUP="users"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="27e2", OWNER="kenny", GROUP="users"
      '';
    };
    udisks2.enable = true;
    ddccontrol.enable = true;
    zerotier-home = {
      enable = true;
#      zeronsd = {
#        enable = true;
#        package = pkgs.zeronsd;
#      };
    };
  };

  zramSwap.enable = true;

  ########################################
  # Fonts
  ########################################
  fonts = {
    # ln -s /run/current-system/sw/share/X11/fonts ~/.local/share/fonts
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
  #  security.pam.services = {
  #    # login.u2fAuth = true;
  #    sudo.u2fAuth = true;
  #  };

  # Ask for password first for swaylock
  security.pam.services.swaylock.rules.auth.fprintd.order =
    config.security.pam.services.swaylock.rules.auth.unix.order + 10;
  # Allow null password to fall-back to fprintd
  security.pam.services.swaylock.rules.auth.unix.settings.nullok = lib.mkForce true;

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

  # Allow input access of espanso
  security.wrappers.espanso = {
    source = "${pkgs.espanso-wayland}/bin/espanso";
    capabilities = "cap_dac_override+p";
    owner = "root";
    group = "root";
  };

  #  services.espanso.enable = true;
  #  systemd.user.services.espanso.serviceConfig.ExecStart = lib.mkForce "/run/wrappers/bin/espanso worker";

  # Building mongodb takes forever. Pin it here so
  # it can be copied to other stores
  # system.extraDependencies = [pkgs.mongodb-5_0];

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
    immich-go # local
    libreoffice-fresh
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
    ratarmount # Mount tar/archives with FUSE
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
    genpass
    gopass # replacement for pass, has -o option
    gopass-jsonapi
    qtpass
    rage
    yubikey-manager
    yubikey-personalization
    yubioath-flutter

    # Video
    ffmpeg
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
    compsize # Show on-disk file size
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
    dante
    openconnect
    tun2proxy

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
    tdesktop
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

    # AI
    # llama-cpp
    # python3Packages.huggingface-hub
    # ollama

    # General/Unsorted
    pinta
    qalculate-gtk

    # Virtualization
    nixos-generators
    virt-manager

    # Version Control related
    # gitFull
    git-absorb # git commit --fixup, but automatic
    git-no-hooks
    git-filter-repo
    git-lfs
    gita # Update a group of repos
    gitui
    jujutsu # jj command for git, to try out

    # Development
    act # Run your GitHub Actions locally
    amazon-ecs-cli
    android-tools
    aws-adfs
    awscli2
    aws-azure-login
    bintools
    binwalk
    bruno # Postman like API tool
    clang-tools
    delta
    difftastic
    direnv
    dtc
    file
    gdb
    gh
    gnumake
    hotspot
    insomnium # Postman like API tool - :( no longer maintained
    jq
    llvm
    man-pages
    meld
    meson-tools
    miller # mlr convert csv to json: mlr --c2j --jlistwrap cat
    mold
    # nix-bubblewrap
    nix-direnv
    parallel
    perf
    pkgconf
    pgcli
    ripgrep
    tio
    yamllint
    stable.yamlfix # broken 2024-03-29

    # Testing
    atuin # shell history in sqlite?
    hashcat
    gnome.seahorse
    libsmbios # smbios-thermal-ctl
    modprobed-db
    nushell # odd different shell
    phinger-cursors
    tessen # password dmenu
    # Broken: 2023-10-26 azure-cli
    # bcompare
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        wlrobs
      ];
    })
    steam-run
    lutris
    # TODO: broken 2024-02-11 mitmproxy
    mitmproxy

    # s0ix-selftest-tool

    # My Packages
    # dcc -- wait until openssl3 supported
    fre
    sd

    # Testing from https://github.com/b3nj5m1n/dotfiles
    aria # Basically a better wget
    atuin # Save & search shell history
    du-dust # More intuitive du
    eza # Better ls
    tealdeer # tldr

    deptree

    xdg-desktop-portal-wlr
    imhex

    tpm2-tools
    tpm2-tss

    (pkgs.writeTextFile {
      name = "dbus-sway-environment";
      destination = "/bin/dbus-sway-environment";
      executable = true;

      text = ''
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
        systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
        systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      '';
    })

    pcscliteWithPolkit.out
  ];
}
