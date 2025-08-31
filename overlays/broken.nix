self: super: let
  stablePackages = [
    # 2025-08-30
    "checkov"
    "goose-cli"
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
