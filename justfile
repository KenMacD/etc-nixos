
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
  statix check

# Attempt a host build to verify it works
build host=current_host *args:
  nix build {{args}} --no-link .#nixosConfigurations.{{host}}.config.system.build.toplevel

build-no-warns host=current_host *args:
  nix build {{args}} --no-link --option abort-on-warn true --show-trace .#nixosConfigurations.{{host}}.config.system.build.toplevel

# TODO: deploy-rs or colmena? (also check --build-host hz)
deploy host:
  nixos-rebuild switch --target-host {{host}}.$(tailscale status --json | jq -r '.CurrentTailnet.MagicDNSSuffix') --use-substitutes --elevate=sudo --ask-elevate-password --flake .#{{host}}

deploy-dry-activate host:
  nixos-rebuild dry-activate --target-host {{host}}.$(tailscale status --json | jq -r '.CurrentTailnet.MagicDNSSuffix') --use-substitutes --elevate=sudo --ask-elevate-password --flake .#{{host}}

deploy-boot host:
  nixos-rebuild boot --target-host {{host}}.$(tailscale status --json | jq -r '.CurrentTailnet.MagicDNSSuffix') --use-substitutes --elevate=sudo --ask-elevate-password --flake .#{{host}}

# Run a dry-activate to see what will change
dry-activate:
  nixos-rebuild dry-activate --no-reexec --flake .#{{current_host}}

# Switch to a new configuration
switch:
  nixos-rebuild switch --sudo --no-reexec --flake .#{{current_host}}

check-dups:
  nix run github:notashelf/flint
