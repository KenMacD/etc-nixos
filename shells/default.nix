{
  lib,
  pkgs,
}:
with builtins;
with lib;
  listToAttrs (
    map (name: {
      name = removeSuffix ".nix" name;
      value = import (./. + "/${name}") {inherit lib pkgs;};
    })
    (filter (file: hasSuffix ".nix" file && file != "default.nix")
      (attrNames (readDir ./.)))
  )
