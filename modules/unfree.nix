{ lib, nixpkgs, ... }:

with lib;

{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "steam" ];
}

