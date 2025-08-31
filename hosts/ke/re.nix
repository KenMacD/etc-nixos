{
  config,
  lib,
  pkgs,
  ...
}: {
  ########################################
  # Packages
  ########################################
  programs.ghidra = {
    enable = true;
    package = pkgs.ghidra-bin;
  };

  environment.systemPackages = with pkgs; [
    iaito # r2 gui
    # Requires manual download, add when needed: ida-free
    radare2
    cutter
    rizin
  ];
}
