{ config, pkgs, ... }:

{
  ########################################
  # Nix
  ########################################
  system.stateVersion = "20.09";
  nix.autoOptimiseStore = true;
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      gnupg = pkgs.gnupg.override { libusb1 = pkgs.libusb1; };

      # Allow unstable.PackageName
      unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
    };
  };

  # Include current config:
  environment.etc.current-nixos-config.source = ./.;

  # Include a full list of installed packages
  environment.etc.current-system-packages.text = let
    packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in formatted;

  # Allow edit of /etc/host for temporary mitm:
  environment.etc.hosts.mode = "0644";

  ########################################
  # Hardware
  ########################################
  hardware = {
    cpu.intel.updateMicrocode = true;
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

  ########################################
  # Locale
  ########################################
  time.timeZone = "America/Halifax";
  i18n.defaultLocale = "en_CA.UTF-8";

  ########################################
  # Boot
  ########################################
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.zfs.enableUnstable = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ turbostat ];
  boot.kernelParams =
    [ "workqueue.power_efficient=1" "battery.cache_time=10000" ];
  powerManagement.enable = true;

  boot.tmpOnTmpfs = true;

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
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    usePredictableInterfaceNames = false;
    useDHCP = false; # deprecated
    wireless.enable = false;
    wireless.iwd.enable = true;
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  ########################################
  # Sound
  ########################################
  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true; # for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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

      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
      gnome3.adwaita-icon-theme
    ];
  };
  programs.waybar.enable = true;
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

  ########################################
  # Systemd
  ########################################
  # Allow larger coredumps
  systemd.coredump.extraConfig = ''
    #Storage=external
    #Compress=yes
    #ProcessSizeMax=2G
    ProcessSizeMax=10G
    #ExternalSizeMax=2G
    ExternalSizeMax=10G
    #JournalSizeMax=767M
    #MaxUse=
    #KeepFree=
  '';

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
  programs.fish.enable = true;
  programs.vim.defaultEditor = true;
  users.users.kenny = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "docker" "networkmanager" "wheel" ];
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
    storageDriver = "zfs";
  };

  ########################################
  # Security
  ########################################
  programs.browserpass.enable = true;
  programs.firejail = {
    enable = true;
    wrappedBinaries = { teams = "${pkgs.lib.getBin pkgs.teams}/bin/teams"; };
  };

  ########################################
  # Packages
  ########################################
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
      (firefox.override { forceWayland = true; })
      fzf
      google-chrome
      htop
      httpie
      kitty
      libusb1
      libva-utils
      p7zip
      plocate
      python3
      tmux
      xdg-utils

      # Password management
      (pass.override {
        x11Support = false;
        waylandSupport = true;
      })
      qtpass
      yubikey-manager
      yubikey-personalization

      # Sound
      cmus
      pavucontrol
      pamixer
      pulseeffects-pw

      # Video
      intel-gpu-tools
      v4l_utils

      # Graphics
      glxinfo
      mesa_glu

      # System management
      bcc
      polkit_gnome
      iotop
      killall
      fwupd
      nixfmt
      powertop
      pstree
      turbostat

      # Networking
      openconnect

      # Communication
      irssi
      signal-desktop
      slack
      # teams -- Included in firejail
      (weechat.override {
        configure = { availablePlugins, ... }: {
          plugins = with availablePlugins; [ python ];
          scripts = with pkgs.weechatScripts; [
            (weechat-matrix.overridePythonAttrs (oldAttrs: rec {
              version = "d67821ae50dbfc86e9aa03709aa2a752aee705f6";
              src = fetchFromGitHub {
                owner = "poljar";
                repo = "weechat-matrix";
                rev = "d67821ae50dbfc86e9aa03709aa2a752aee705f6";
                sha256 = "01zisps5fx4i3vkrir8k04arcqf0n5i84a4nf0m9c2k48312dzf6";
              };
            }))
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
      mutt
      w3m
      urlview

      # Development
      any-nix-shell
      aws-adfs
      awscli2
      bintools
      clang
      direnv
      file
      gdb
      gh
      gnumake
      hotspot
      jq
      llvm
      manpages
      nix-direnv
      parallel
      perf
      direnv
      git
      ripgrep
      rustup
      vscode-fhs # TODO: build with extensions

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
