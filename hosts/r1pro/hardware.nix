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

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "UUID=1e8a0c0b-7f51-4074-90d7-3cae56d527c5";
    fsType = "bcachefs";
    # Filesystem can do an upgrade/repair on boot
    options = [
      "fsck"
      "fix_errors"
      "x-systemd.device-timeout=1h"
      "x-systemd.device-timeout=1h"
    ];
  };

  fileSystems."/boot" = {
    device = "UUID=8EC3-189B";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/bd5faf83-dd5f-460d-bce5-879dcdf7ac66";
    }
  ];

  # TODO: move to networking
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # TODO: set?
  # powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";
}
