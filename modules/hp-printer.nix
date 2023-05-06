{ lib, pkgs, ... }:

with lib;

{
  services.printing.enable = true;
  hardware.sane.enable = true;
  users.users.kenny.extraGroups = [ "scanner" "lp" ];
  hardware.sane.extraBackends = [ pkgs.hplipWithPlugin ];
  services.printing.drivers = [ pkgs.hplipWithPlugin ];
}
