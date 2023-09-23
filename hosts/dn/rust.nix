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
    rustup
    cargo-crev
  ];
}
