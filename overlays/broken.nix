self: super: let
  stablePackages = [
    "nix-alien"
    "copyq"
    "jamesdsp"

    "libfprint-2-tod1-goodix"
    "fprintd-tod"
  ];

  masterPackages = [
  ];

  mapToStable = pkgName: super.stable.${pkgName};
  mapToMaster = pkgName: super.master.${pkgName};

  stableOverrides = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = mapToStable name;
    })
    stablePackages
  );

  masterOverrides = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = mapToMaster name;
    })
    masterPackages
  );
in
  stableOverrides // masterOverrides
