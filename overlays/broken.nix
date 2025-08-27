self: super: let
  stablePackages = [
    # 2025-08-26
    "checkov"
    "gitui"
    "goose-cli"
    "mdcat"
  ];

  masterPackages = [
    # 2025-08-26
    "aider-chat"
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
