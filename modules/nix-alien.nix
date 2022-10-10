{ lib, pkgs, nix-alien, ... }:

with lib;

{
  programs.nix-ld.enable = true;
  environment.systemPackages =  with pkgs; with nix-alien.packages.${system}; [
    nix-alien
    nix-index
    nix-index-update
  ];
}
