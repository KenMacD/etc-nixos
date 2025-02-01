{
  config,
  lib,
  pkgs,
  ...
}: {
  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs;
  with config.boot.kernelPackages; [
    ghidra-bin
    iaito # r2 gui
    radare2
    cutter
    rizin

    # Android
    # TODO: Installs insecure dotnet avalonia-ilspy
  ];
}
