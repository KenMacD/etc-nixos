final: prev: let
  stablePackages = [
    # Broken: 2026-10-16
    "dash-mpd-cli"
  ];

  masterPackages = [
  ];

  mapToStable = pkgName: prev.stable.${pkgName};
  mapToMaster = pkgName: prev.master.${pkgName};

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
