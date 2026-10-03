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
    options = ["subvol=nixos_root" "noatime" "space_cache=v2"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=home" "noatime" "space_cache=v2"];
  };

  fileSystems."/var/lib/docker" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=var_lib_docker" "noatime" "space_cache=v2"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/19453858-b1c4-459d-a09c-6bc96df06442";
    fsType = "btrfs";
    options = ["subvol=nixos_nix" "noatime" "space_cache=v2"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DBDC-FF45";
    fsType = "vfat";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/d32bc8af-e3e6-4779-b084-eddb41415b8a";}
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";
}
