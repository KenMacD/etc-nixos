{ config, lib, pkgs, ... }: {

  # Not great, but okay enough for now:
  system.activationScripts.signbl = lib.stringAfter [ "etc" ]
  ''
    ${pkgs.sbctl}/bin/sbctl sign-all
  '';

  environment.systemPackages = with pkgs; [
    sbctl
  ];
}
