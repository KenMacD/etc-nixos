{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    python3SystemPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "List of Python3 packages to install system-wide";
    };
  };
}
