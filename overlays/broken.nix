self: super: let
  stablePackages = [
    # TODO: broken on 2024-08-15
    "quickgui"

    # TODO: broken on 2024-10-10
    "checkov"

    # TODO: broken on 2024-10-16
    "azure-cli"
    "cutter"
    "distrho"
    "open-webui"
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
