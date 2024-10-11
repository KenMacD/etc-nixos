{
  config,
  lib,
  pkgs,
  nixpkgs,
  inputs,
  system,
  ...
}: {
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
  nixpkgs.config = {};

  ########################################
  # Hardware
  ########################################
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      # driSupport32Bit = true;
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
    hostName = "an";
    hostId = "822380ad";
    useDHCP = false;
    useNetworkd = true;
    usePredictableInterfaceNames = false;
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

  networking.resolvconf.dnsSingleRequest = true;
  networking.wireless.interfaces = ["wlan0"];
  networking.interfaces.wlan0.useDHCP = true;
  networking.wireless = {
    allowAuxiliaryImperativeNetworks = true;
    enable = true;
    userControlled = {
      enable = true;
      group = "users";
    };
  };

  ########################################
  # Desktop Environment
  ########################################
  # services.xserver.desktopManager.plasma6.enable' defined in `/nix/store/qhyi6iczshf7s9qd36jfvb3sdqmnpnk7-source/hosts/an/configuration.nix' has been renamed to `services.desktopManager.plasma6.enable'.
  # services.xserver.layout' defined in `/nix/store/qhyi6iczshf7s9qd36jfvb3sdqmnpnk7-source/hosts/an/configuration.nix' has been renamed to `services.xserver.xkb.layout'.
  # services.xserver.libinput.touchpad' defined in `/nix/store/qhyi6iczshf7s9qd36jfvb3sdqmnpnk7-source/hosts/an/configuration.nix' has been renamed to `services.libinput.touchpad'.
  # services.xserver.libinput.enable' defined in `/nix/store/qhyi6iczshf7s9qd36jfvb3sdqmnpnk7-source/hosts/an/configuration.nix' has been renamed to `services.libinput.enable'.
  # services.xserver.displayManager.sddm.enable' defined in `/nix/store/qhyi6iczshf7s9qd36jfvb3sdqmnpnk7-source/hosts/an/configuration.nix' has been renamed to `services.displayManager.sddm.enable'.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.enable = true;
  services.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = true;
      middleEmulation = true;
      tapping = false;
      tappingDragLock = false;
    };
  };
  #  services.xserver = {
  #    enable = true;
  #    #desktopManager.plasma5.enable = true;
  #    layout = "us";
  #  };

  ########################################
  # Services
  ########################################
  services = {
    flatpak.enable = true;
    fwupd.enable = true;
    openssh.enable = true;
    pcscd.enable = true;
    thermald.enable = true;
    udisks2.enable = true;
    printing.enable = true;
    printing.drivers = [pkgs.hplipWithPlugin];
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
    uid = 1000;
    extraGroups = [
      "dialout"
      "networkmanager"
      "video"

      "scanner"
      "lp"
    ];
  };
  users.users.angela = {
    uid = 1001;
    isNormalUser = true;
    createHome = true;
    extraGroups = [
      "dialout"
      "networkmanager"
      "video"

      "scanner"
      "lp"

      "wheel"
    ];
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
  environment.systemPackages = with pkgs;
  with config.boot.kernelPackages; [
    # General
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    chromium
    digikam
    exiftool
    ffmpeg
    firefox
    libreoffice-fresh
    p7zip
    powertop
    signal-desktop
    soundkonverter
    vim
    vlc

    # tmp
    shotwell
    git
    losslesscut-bin
    fwupd
    fwupd-efi

    wpa_supplicant
    wpa_supplicant_gui
  ];
}
