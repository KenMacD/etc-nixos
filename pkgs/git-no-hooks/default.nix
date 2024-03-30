{
  stdenv,
  lib,
  gitFull,
}:
gitFull.overrideAttrs(old: {
  patches = (old.patches or []) ++ [./git-no-hooks.patch];
  doInstallCheck = false;
})
