{
  config,
  lib,
  pkgs,
  ...
}: {
  nix.settings.extra-substituters = ["https://cache.dataaturservice.se/spectrum/"];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "spectrum-os.org-1:rnnSumz3+Dbs5uewPlwZSTP0k3g/5SRG4hD7Wbr9YuQ="
  ];
}
