self: super: let
  stablePackages = [

    # TODO: broken on 2024-10-16
    "cutter"

    # TODO: broken on 2024-11-17
    "mitmproxy"
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
