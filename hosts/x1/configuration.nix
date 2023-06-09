{
  config,
  pkgs,
  ...
}: {
  imports = [];

  ########################################
  # Nix
  ########################################
  system.autoUpgrade.enable = true;
  nix.autoOptimiseStore = true;
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
  # Boot
  ########################################
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [
    "i915.enable_psr=1"
    #    "pcie_aspm=off"
  ];

  # Spins the fan up and down too often with turbo
  boot.postBootCommands = ''
    echo "1" >/sys/devices/system/cpu/intel_pstate/no_turbo
  '';

  ########################################
  # ZFS
  ########################################
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.enableUnstable = true;
  services.zfs.autoSnapshot.enable = true;
  services.zfs.trim.enable = true;

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

  ########################################
  # Sound
  ########################################
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  ########################################
  # Desktop Environment
  ########################################
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    layout = "us";
    displayManager = {sddm.enable = true;};
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
  services.tlp.enable = true;
  powerManagement.powertop.enable = true;

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

    # Music
    gtkpod
    ffmpeg
    soundkonverter
  ];
}
