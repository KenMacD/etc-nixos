{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "depsguard";
  version = "0.1.40";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "arnica";
    repo = "depsguard";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ry20L5aUzrZZYQIR1Q9Ly4Pu1dDM1hPdyCNOr6wrLlU=";
  };

  # The `apply_selected_applies_selected` test writes config backups into
  # $HOME/.depsguard/backups via fix::backup_file. The Nix sandbox sets
  # HOME=/homeless-shelter (non-writable), so point HOME at a writable tmp dir.
  preCheck = ''
    export HOME="$TMPDIR"
  '';

  # Two integration tests are environmentally non-hermetic:
  #  - npmrc_round_trip_all_keys: hard-asserts exit 1, which requires `npm`
  #    on PATH (not present in the sandbox).
  #  - scan_shows_action_needed_for_fresh_home: expects actionable findings,
  #    but the repo's own .github/dependabot.yml is discovered and shown SECURE.
  # All other integration tests guard on has_command/has_wine and skip cleanly.
  checkFlags = [
    "--skip"
    "npmrc_round_trip_all_keys"
    "--skip"
    "scan_shows_action_needed_for_fresh_home"
  ];

  cargoHash = "sha256-9LUbu21Uhi5vuQz+Y2vGSHCDEiOUyVCwNwlbWZaHyRQ=";

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Harden your package manager configs against supply chain attacks";
    homepage = "https://github.com/arnica/depsguard";
    changelog = "https://github.com/arnica/depsguard/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "depsguard";
  };
})
