{ lib, pkgs, nix-alien, ... }:

with lib;

{
  nixpkgs.overlays = [
    nix-alien.overlay
  ];

  programs.nix-ld.enable = true;
  environment.systemPackages = [
    pkgs.nix-alien
    pkgs.nix-index
    pkgs.nix-index-update
  ];
}
