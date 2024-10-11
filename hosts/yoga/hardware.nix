{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=nixos_root" "noatime"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=home" "noatime"];
  };

  fileSystems."/var/lib/docker" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=var_lib_docker" "noatime"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=nixos_nix" "noatime"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DBDC-FF45";
    fsType = "vfat";
  };

  fileSystems."/run/media/black" = {
    device = "/dev/disk/by-uuid/779defff-0c31-4144-9cc7-840a17f7bdb6";
    fsType = "btrfs";
    options = [
      "noauto"
      "nofail"
      "subvolid=0"
      "x-systemd.automount"
      "x-systemd.device-timeout=1ms"
      "x-systemd.idle-timout=5m"
    ];
  };

  fileSystems."/run/media/silver" = {
    device = "/dev/disk/by-uuid/1a5da77a-2086-4ca8-8f36-836d956b7035";
    fsType = "btrfs";
    options = [
      "noauto"
      "nofail"
      "subvolid=0"
      "x-systemd.automount"
      "x-systemd.device-timeout=1ms"
      "x-systemd.idle-timout=5m"
    ];
  };

  fileSystems."/run/media/red" = {
    device = "/dev/disk/by-uuid/e07ab464-3fe4-448c-891c-f94e96224f96";
    fsType = "btrfs";
    options = [
      "noauto"
      "nofail"
      "subvolid=0"
      "x-systemd.automount"
      "x-systemd.device-timeout=1ms"
      "x-systemd.idle-timout=5m"
    ];
  };

  fileSystems."/mnt/easy" = {
    device = "/dev/disk/by-uuid/fd308d96-c40d-4eab-b9b4-4440390cb27f";
    fsType = "bcachefs";
    options = [
      "x-systemd.mount-timeout=45m"
    ];
  };

  fileSystems."/mnt/multimedia" = {
    depends = [
      "/mnt/easy"
    ];
    device = "/mnt/easy/multimedia";
    fsType = "none";
    options = ["bind"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/d32bc8af-e3e6-4779-b084-eddb41415b8a";}
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";
}
