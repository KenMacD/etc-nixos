{ config, lib, pkgs, ... }: {

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs;
    with config.boot.kernelPackages; [
      ghidra-bin
      radare2
      cutter
      rizin

      # Android
      avalonia-ilspy
    ];
}
