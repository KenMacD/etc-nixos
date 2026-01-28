
current_host := `hostname`


# Check flake validity
check:
  nix flake check path:/home/kenny/src/nixos

# Update flake.lock to newest versions
update:
  nix flake update --flake .

# Format Nix files
format:
  alejandra .

# Lint the repository
lint:
  nixpkgs-lint .

# Attempt a host build to verify it works
build host=current_host *args:
  nix build {{args}} --no-link .#nixosConfigurations.{{host}}.config.system.build.toplevel

build-no-warns host=current_host *args:
  nix build {{args}} --no-link --option abort-on-warn true --show-trace .#nixosConfigurations.{{host}}.config.system.build.toplevel

# Run a dry-activate to see what will change
dry-activate:
  nixos-rebuild dry-activate --no-reexec --flake .#{{current_host}}

# Switch to a new configuration
switch:
  nixos-rebuild switch --sudo --no-reexec --flake .#{{current_host}}
