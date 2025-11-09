{ lib
, ...
}:

# Borrowed from: https://github.com/shiryel/fennecOS/blob/71f0abacb376c2560d7a15d5c71162c5d70a1c6d/lib/default.nix

with builtins;
with lib;

# .extend from `makeExtensible`
lib.extend (final: prev:
let
  my_lib = pipe ./. [
    filesystem.listFilesRecursive
    (filter (file: hasSuffix ".nix" file && file != ./default.nix))
    (map (file: import file { lib = final; }))
    (foldr recursiveUpdate { })
  ];
in
assert isAttrs my_lib;
assert isFunction my_lib.snitchRule;
my_lib
)
