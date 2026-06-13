# NixOS Repository Guide for LLM Agents

## Quick Start Context

This is a NixOS system configuration managed with Nix flakes. When working on this repository, you are helping maintain a declarative, reproducible system configuration that manages multiple hosts, packages, services, and development environments.

## Critical Information for Agents

### Repository Structure

```text
├── flake.nix           # Main flake definition - START HERE
├── flake.lock          # Lock file - DO NOT manually edit
├── common.nix          # Shared configuration across all hosts
├── unfree.nix          # Allowed unfree packages list
├── justfile            # Command aliases - USE THESE COMMANDS
├── .sops.yaml          # Secrets management configuration
├── hosts/              # Host-specific configurations
│   └── <hostname>/     # Individual machine configs
├── modules/            # Reusable NixOS modules
├── pkgs/               # Custom package definitions
└── overlays/           # Package modifications/overrides
    ├── broken.nix      # Packages switched to stable/master
    └── testing.nix     # Temporary patches/testing overrides
```

### Essential Commands (Always Use These)

```bash
# Check configuration validity
just check

# Format all Nix files
just format

# Build and switch system
just switch

# Update flake inputs
just update

# Show available commands
just --list
```

**IMPORTANT**: Always use `just` commands instead of raw `nix` commands for consistency.

### NixOS MCP Server

A **NixOS MCP server** is available with two tools for live NixOS ecosystem queries. **Always prefer these over guessing from training data** — nixpkgs moves fast and training data is months behind.

| Tool | Purpose |
|------|----------|
| `nixos_nix` | Search/info for packages, NixOS/Home Manager/nixvim/Darwin options, channels, binary cache, wiki, nix.dev, flakes, /nix/store |
| `nixos_nix_versions` | Package version history with commit hashes and dates from NixHub.io |

**When to use:**
- Looking up if a package exists in nixpkgs and its current version
- Searching for NixOS, Home Manager, or nixvim options
- Checking if a package has a prebuilt binary in the cache
- Finding which commit introduced a specific package version
- Looking up NixOS wiki articles or nix.dev documentation
- Listing available channels and their indexed commits
- Browsing Home Manager option trees

**Quick reference:**

```
# Search for a package
mcp({ server: "nixos", tool: "nixos_nix", args: '{"action":"search","query":"ripgrep"}' })

# Get package info
mcp({ server: "nixos", tool: "nixos_nix", args: '{"action":"info","query":"git","type":"package"}' })

# Search NixOS options
mcp({ server: "nixos", tool: "nixos_nix", args: '{"action":"search","query":"services.nginx","type":"options"}' })

# Search Home Manager options
mcp({ server: "nixos", tool: "nixos_nix", args: '{"action":"search","query":"programs.git","source":"home-manager"}' })

# Check binary cache
mcp({ server: "nixos", tool: "nixos_nix", args: '{"action":"cache","query":"hello","system":"x86_64-linux"}' })

# List channels
mcp({ server: "nixos", tool: "nixos_nix", args: '{"action":"channels"}' })

# Package version history
mcp({ server: "nixos", tool: "nixos_nix_versions", args: '{"package":"nodejs","limit":5}' })
```

### Key Technologies Stack

- **Nix Flakes**: Reproducible builds and dependency management
- **NixOS Modules**: Composable system configuration components
- **sops-nix**: Encrypted secrets management (keys in `.sops.yaml`)
- **disko**: Declarative disk management
- **lanzaboote**: Secure boot implementation
- **Multiple Nixpkgs**: unstable (default), stable (24.11, 25.05), master

### Working with Configurations

#### Adding New Packages

1. **System packages**: Add to host config or `common.nix`
2. **Custom packages**: Define in `pkgs/` directory
3. **Unfree packages**: Add to `unfree.nix` first
4. **Broken packages**: Use `overlays/broken.nix` to switch branches

#### Module Development

- Create reusable modules in `modules/`
- Import modules in host configs or `common.nix`
- Follow NixOS module conventions (options, config, etc.)

#### Host Management

- Each host has its own directory in `hosts/<hostname>/`
- Host configs import `common.nix` for shared settings
- Hardware-specific settings go in host directories

### Development Workflows

#### Making Changes

1. Edit configuration files
2. Run `just check` to validate syntax
3. Run `just format` to format code
4. Test with `just build` before switching
5. Apply with `just switch`

#### Package Overrides

- **Temporary fixes**: Use `overlays/testing.nix`
- **Broken packages**: Use `overlays/broken.nix` to switch to stable/master
- **Custom versions**: Define in `pkgs/` directory

#### Secrets Management

- Secrets are encrypted with sops-nix
- Key management defined in `.sops.yaml`
- Never commit plaintext secrets

### Code Style and Conventions

- **Formatting**: All Nix code must be formatted with `alejandra`
- **Module structure**: Follow NixOS module conventions
- **Imports**: Use relative paths for local modules
- **Comments**: Document complex configurations
- **Naming**: Use descriptive names for custom packages/modules

### Common Patterns

#### Adding a New Service

```nix
# In appropriate module or host config
services.myservice = {
  enable = true;
  # service-specific options
};
```

#### Custom Package Definition

```nix
# In pkgs/default.nix or pkgs/<package>/default.nix
{ stdenv, fetchFromGitHub, ... }:
stdenv.mkDerivation rec {
  pname = "my-package";
  version = "1.0.0";
  # derivation definition
}
```

#### Module Creation

```nix
# In modules/<module-name>.nix
{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    # define options
  };

  config = mkIf config.<module-name>.enable {
    # implementation
  };
}
```

### Troubleshooting Tips

- Check `just check` output for syntax errors
- Use `nix flake show` to see available outputs
- Check `flake.lock` for input versions
- Look in `overlays/broken.nix` if packages are failing to build
- Secrets issues: verify `.sops.yaml` configuration

### Development Shells

The flake provides pre-configured development environments accessible via:
```bash
nix develop .#<shell-name>
```

### Important Notes for Agents

- **Never manually edit `flake.lock`** - use `just update`
- **Always run `just format`** before proposing changes
- **Test with `just check`** before building
- **Use `just` commands** instead of raw nix commands
- **Check `unfree.nix`** when adding proprietary packages
- **Respect the module system** - don't put everything in one file
- **Consider security** - use sops-nix for sensitive data
- **Use the NixOS MCP server** for live package/option lookups instead of guessing from training data

### Getting Help

- Run `just --list` to see all available commands
- Check `flake.nix` for available outputs and development shells
- Look at existing host configs for patterns
- Review module examples in `modules/` directory
