{
  config,
  lib,
  pkgs,
  ...
}: {
  # Not great, but okay enough for now:
  system.activationScripts.signbl =
    lib.stringAfter ["etc"]
    ''
      ${pkgs.sbctl}/bin/sbctl sign-all 2>/dev/null || true
      for f in /boot/EFI/nixos/*-linux-*-bzImage.efi; do ${pkgs.sbctl}/bin/sbctl sign $f; done
    '';

  environment.systemPackages = with pkgs; [
    sbctl
  ];
}
