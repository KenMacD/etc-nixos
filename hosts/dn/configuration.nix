{ config, pkgs, ... }:

{
  ########################################
  # Nix
  ########################################
  nix.useSandbox = true;
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


  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.zfs.enableUnstable = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ turbostat ];
  boot.kernelParams =
    [ "workqueue.power_efficient=1" "battery.cache_time=10000" ];
  powerManagement.enable = true;

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
  users.users.kenny = {
    extraGroups = [ "docker" "libvirtd" "networkmanager" ];
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
      (firefox.override { forceWayland = true; })
      fzf
      google-chrome
      htop
      httpie
      kitty
      libreoffice
      libusb1
      libva-utils
      p7zip
      python3
      tmux
      unzip
      xdg-utils

      # Password management
      (pass.override {
        x11Support = false;
        waylandSupport = true;
      })
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
      intel-speed-select
      iotop
      killall
      lxqt.lxqt-policykit
      ncdu # disk usage with file count
      nixfmt
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
      mutt
      w3m
      urlview

      # Android
      abootimg
      android-tools
      heimdall
      brotli

      # Games
      wine
      winetricks

      # General/Unsorted
      magic-wormhole
      sshfs

      # Virtualization
      virt-manager

      # Development
      amazon-ecs-cli
      aws-adfs
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
      gitFull
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
