{ lib, pkgs, inputs, ... }:

with lib;

{
  programs.nix-ld.enable = true;
  environment.systemPackages =  with pkgs; with inputs.nix-alien.packages.${system}; [
    nix-alien
    nix-index
    nix-index-update
  ];
}
