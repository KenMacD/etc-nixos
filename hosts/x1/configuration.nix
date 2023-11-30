{
  config,
  pkgs,
  ...
}: {
  imports = [ ];

  ########################################
  # Nix
  ########################################
  system.autoUpgrade.enable = true;
  # nix.gc.automatic = true;
  nixpkgs.config.packageOverrides = pkgs: {
    old = import <nix-2105> {
      config = config.nixpkgs.config;
    };
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  ########################################
  # Hardware
  ########################################
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    sane = {
      enable = true;
      extraBackends = [pkgs.hplipWithPlugin];
    };
  };
  environment.variables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";

  ########################################
  # Locale
  ########################################
  time.timeZone = "America/Halifax";
  i18n.defaultLocale = "en_CA.UTF-8";

  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "i915.enable_psr=1"
    #    "pcie_aspm=off"
  ];

  # Spins the fan up and down too often with turbo
  boot.postBootCommands = ''
    echo "1" >/sys/devices/system/cpu/intel_pstate/no_turbo
  '';

  ########################################
  # Network
  ########################################
  networking = {
    hostName = "x1";
    hostId = "d3538295";
    usePredictableInterfaceNames = false;
    useDHCP = false;
    # interfaces.wlan0.useDHCP = true;
    networkmanager.enable = true;
  };

  services.resolved.enable = true;

  ########################################
  # Sound
  ########################################
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  ########################################
  # Desktop Environment
  ########################################
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    layout = "us";
    displayManager = {
      #      autoLogin.enable = true;
      #      autoLogin.user = "anglea";
      sddm.enable = true;
    };
    libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = true;
        middleEmulation = true;
        tapping = false;
        tappingDragLock = false;
      };
    };
  };

  ########################################
  # Power
  ########################################
  services.upower.enable = true;
  powerManagement.powertop.enable = true;
  services.acpid.enable = true;
  services.hardware.bolt.enable = true;

  ########################################
  # Services
  ########################################
  services.printing.enable = true;
  services.printing.drivers = [pkgs.hplipWithPlugin];
  services.fwupd.enable = true;

  ########################################
  # User
  ########################################

  users.users.angela = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "scanner" "lp"];
    uid = 1001;
  };
  users.users.kenny = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "scanner" "lp"];
    uid = 1000;
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    borgbackup
    chromium
    digikam
    firefox
    google-chrome
    p7zip
    powertop
    signal-desktop
    simple-scan
    vim
    vlc

    shotwell
    git
    losslesscut-bin
    fwupd
    fwupd-efi

    libreoffice-fresh

    # Music
    gtkpod
    ffmpeg
    soundkonverter

    iw
    wirelesstools
    wavemon
  ];
}
