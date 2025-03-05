{
  self,
  config,
  lib,
  pkgs,
  system,
  ...
}: let
  local = self.packages.${system};
in {
  imports = [
    ./ai.nix
    ./android.nix
    ./audio.nix
    ./bwrap.nix
    ./disko.nix
    ./emacs.nix
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
    extra-substituters = [
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      # default priority is 40
      "https://nix.home.macdermid.ca?priority=30"
      # "https://nix.macdermid.ca"
    ];
    trusted-public-keys = [
      "nix.home.macdermid.ca:CQuA65gXW8KuFlk9Ufx5oMsAiTZzQhfluNoaOzypXMo="
      "nix.macdermid.ca:sAlwW/Ph4P8pyrUT7pmWnsFeGVyZ7pyXYjUmo41/hc8="
    ];
  };
  nix.extraOptions = ''
    # Ensure we can still build when nix.home.macdermid.ca is not accessible
    fallback = true
  '';

  # When building mongodb enable the following. Otherwise it takes
  # forever just to run out of space
  # see: https://github.com/NixOS/nixpkgs/issues/54707#issuecomment-1132907191
  #systemd.services.nix-daemon = {environment.TMPDIR = "/nix/tmp";};
  #systemd.tmpfiles.rules = ["d /nix/tmp 0755 root root 1d"];

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
        vpl-gpu-rt
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
        pipewire
      ];
    };
    sane = {
      enable = true;
      extraBackends = [pkgs.hplipWithPlugin];
    };
  };
  services.hardware.bolt.enable = true;
  services.avahi.enable = true; # For Chromecast
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.printing.drivers = [pkgs.hplipWithPlugin];

  # Force intel vulkan driver to prevent software rendering:
  environment.variables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";
  environment.variables.LIBVA_DRIVER_NAME = "iHD";
  environment.variables.OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors/";

  boot.kernelParams = [
    # "nohz_full=1-7"
    "preempt=full"
    "nmi_watchdog=0"
    "vm.dirty_writeback_centisecs=6000"

    # TODO: move to common? or maybe just desktop?
    "panic=0"

    "i915.force_probe=!a7a1"
    "xe.force_probe=a7a1"
  ];
  specialisation.i915.configuration = {
    boot.kernelParams = [
      "preempt=full"
      "nmi_watchdog=0"
      "vm.dirty_writeback_centisecs=6000"
      "panic=0"
    ];
  };
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

  # Use Wayland for Electron apps
  environment.variables.NIXOS_OZONE_WL = "1";
  # Clone files as the FS is also clone
  # Odd... tries to clone directories as well as files
  # environment.variables.UV_LINK_MODE = "clone";

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
    kanata = {
      enable = true;
      keyboards = {
        default = {
          # Test cases: <expected>: <input>
          # Ctrl+c: d:CapsLock t:5 d:KeyC t:5 u:KeyC t:5 u:CapsLock t:9000
          # Escape: d:CapsLock t:5 u:CapsLock t:9000
          # CapsLock: d:ShiftLeft t:5 d:ShiftRight t:50 u:ShiftLeft t:5 u:ShiftRight
          #
          # Configs;
          # concurrent-tap-hold required for chords
          # process-unmapped-keys required to avoid swapping order on quick
          #   shift-letters
          extraDefCfg = ''
            concurrent-tap-hold yes
            process-unmapped-keys yes
          '';
          config = ''
            (defsrc
              caps lsft rsft rctl)

            (defseq
              email (k m)
              gmail (g m)
              endash (e n -)
              emdash (e m -)
              ellipsis (. . .)
            )

            (deffakekeys
              email (macro k e n n y S-2 m a c d e r m i d . c a)
              gmail (macro k e n n y . m a c d e r m i d S-2 g m a i l . c o m)

              ;; (unicode _) should work, but Kitty's kitten doesn't like it
              ;; Kitty suggests doing it another way: https://github.com/kovidgoyal/kitty/issues/6559
              endash (macro C-S-u 100 Digit2 Digit0 Digit1 Digit3 ret)
              emdash (macro C-S-u 100 Digit2 Digit0 Digit1 Digit4 ret)
              ellipsis (macro C-S-u 100 Digit2 Digit0 Digit2 Digit6 ret)
            )

            (deflayermap (default-layer)
              ;; tap caps as esc, hold as left control
              caps (tap-hold 100 100 esc lctl)
              ;; rctl as a sequence leader key
              rctl (tap-hold-release 200 200 sldr rctl)
            )

            (defchordsv2-experimental
              (lsft rsft) caps 200 all-released ())
          '';
        };
      };
    };
    kbfs.enable = true; # keybase fs
    keybase.enable = true;
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
    sccache.enable = true;
    snapper = {
      snapshotInterval = "*:0/5";
      cleanupInterval = "1h";
      configs.home = {
        ALLOW_USERS = ["kenny"];
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;

        # Use snapper only for short-term backups:
        TIMELINE_LIMIT_MONTHLY = 1;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
    thermald.enable = true;
    udev = {
      packages = [
        pkgs.yubikey-personalization
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
      dosis
      fira-code
      fira-code-symbols
      font-awesome # Used by waybar
      nerd-fonts.symbols-only
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

      config.programs.ydotool.group
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
  programs.direnv.enable = true;
  programs.git.enable = true;
  programs.partition-manager.enable = true;
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      aws = {
        format = "on [$symbol($profile)(\\[$duration\\] )]($style)";
        symbol = "☁️ ";
      };
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

  programs.sysdig.enable = true;
  programs.thefuck.enable = true;
  programs.ydotool.enable = true;

  python3SystemPackages = with pkgs.python3Packages; [
    uv
  ];

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
    fuse
    fzf
    glib
    httpie
    immich-go
    libnotify
    libreoffice-fresh
    libusb1
    libva-utils
    mongodb-compass
    (nnn.override {withNerdIcons = true;})
    p7zip
    patchelf
    pv
    (python3.withPackages (_: config.python3SystemPackages))
    restic
    ratarmount # Mount tar/archives with FUSE
    rlwrap
    rmlint
    tmux
    sshfs
    unzip
    wl-mirror
    wormhole-william
    xdg-utils
    yt-dlp

    # System performance
    glances
    htop
    stress-ng
    s-tui

    # Terminal related
    glow # Make markdown pretty
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
    sops
    usbutils
    turbostat
    x86_energy_perf_policy

    # Networking
    _3proxy
    cloudflared
    dante
    openconnect
    local.tun2proxy

    # Nix
    alejandra # Nix formatter
    nix-tree
    nixd
    nixpkgs-fmt

    # Wireless
    aircrack-ng

    # Communication
    discord
    irssi
    signal-desktop
    slack
    tdesktop

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
    taskwarrior3
    taskwarrior-tui
    taskopen
    vit

    # AI
    # llama-cpp
    # python3Packages.huggingface-hub
    # ollama

    # General/Unsorted
    ets # Add timestamp to commands
    (pkgs.symlinkJoin {
      name = "gimp";
      paths = [pkgs.gimp];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/gimp \
          --set GDK_BACKEND x11
      '';
    })
    pinta
    spacer # Insert spaces when command stops output
    qalculate-gtk

    # Virtualization
    nixos-generators
    virt-manager

    # Version Control related
    # gitFull
    git-absorb # git commit --fixup, but automatic
    git
    git-extras
    git-filter-repo
    git-lfs
    gita # Update a group of repos
    gitui
    ghorg # clone all repos from an org
    haskellPackages.git-mediate # modify a merge then run to fix it up
    jujutsu # jj command for git, to try out
    pre-commit

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
    local.fwdctrl
    gdb
    gh
    gnumake
    hotspot
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
    ruff
    sqlite-utils
    sqlite
    ssm-session-manager-plugin
    tio
    yamllint
    stable.yamlfix # broken 2024-03-29
    zeal # Offline docs

    # Security tools
    aflplusplus
    bearer

    # Testing
    atuin # shell history in sqlite?
    hashcat
    seahorse
    libsmbios # smbios-thermal-ctl
    modprobed-db
    nushell # odd different shell
    phinger-cursors
    tessen # password dmenu
    # bcompare
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        wlrobs
      ];
    })
    steam-run
    lutris
    mitmproxy
    zed-editor

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

    local.deptree

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
