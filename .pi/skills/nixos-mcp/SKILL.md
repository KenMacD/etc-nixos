---
name: nixos-mcp
description: Query NixOS packages, options, channels, Home Manager, nixvim, Darwin, flakes, binary cache, wiki, and version history via the nixos MCP server. Use when looking up package info, searching NixOS/Home Manager options, checking channel availability, finding package versions, checking binary cache status, reading NixOS wiki, or any task requiring live NixOS/nixpkgs data. Triggers include "is package X available", "search nixpkgs", "nixos option for", "home-manager option", "which channel", "nixos wiki", "package version history", "binary cache", "nixhub", or any NixOS ecosystem lookup.
---

# NixOS MCP Server

Query the NixOS ecosystem via two MCP tools: `nixos_nix` and `nixos_nix_versions`. These provide live data from nixpkgs, NixOS options, Home Manager, Darwin, nixvim, FlakeHub, the NixOS wiki, nix.dev, Noogle, and NixHub — always prefer these over stale training data or manual web scraping.

All tools are called through the MCP gateway with `mcp({ server: "nixos", tool: "...", args: "..." })`.

## Tool Overview

| Tool | Purpose |
|------|---------|
| `nixos_nix` | Search/info for packages, options, wiki, docs, channels, cache, flakes, /nix/store |
| `nixos_nix_versions` | Package version history from NixHub.io |

## 1. `nixos_nix` — Main Query Tool

### Common Actions

| Intent | Action | Example Args |
|--------|--------|-------------|
| Search packages | `search` | `{"action":"search","query":"firefox","type":"packages"}` |
| Get package info | `info` | `{"action":"info","query":"git","type":"package"}` |
| Search NixOS options | `search` | `{"action":"search","query":"services.nginx","type":"options"}` |
| Get option details | `info` | `{"action":"info","query":"services.nginx.enable","type":"option"}` |
| Search Home Manager options | `search` | `{"action":"search","query":"programs.git","source":"home-manager"}` |
| Browse Home Manager option tree | `browse` | `{"action":"browse","query":"programs.git","source":"home-manager"}` |
| Search Darwin options | `search` | `{"action":"search","query":"programs","source":"darwin"}` |
| Search nixvim options | `search` | `{"action":"search","query":"colorscheme","source":"nixvim"}` |
| List channels | `channels` | `{"action":"channels"}` |
| Check binary cache | `cache` | `{"action":"cache","query":"hello"}` |
| Search NixOS wiki | `search` | `{"action":"search","query":"flakes","source":"wiki"}` |
| Search nix.dev docs | `search` | `{"action":"search","query":"overlays","source":"nix-dev"}` |
| Read nix.dev page | `info` | `{"action":"info","query":"tutorials/nix-language","source":"nix-dev"}` |
| Search Noogle (Nix functions) | `search` | `{"action":"search","query":"map","source":"noogle"}` |
| Package statistics | `stats` | `{"action":"stats"}` |
| List flake inputs | `flake-inputs` | `{"action":"flake-inputs"}` |
| Read /nix/store file | `store` | `{"action":"store","type":"read","query":"/nix/store/.../file"}` |
| List /nix/store directory | `store` | `{"action":"store","type":"ls","query":"/nix/store/..."}` |
| Search what programs a package provides | `search` | `{"action":"search","query":"git","type":"programs"}` |

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `action` | ✅ | — | `search`, `info`, `stats`, `browse`, `channels`, `flake-inputs`, `cache`, `store` |
| `query` | ❌ | `""` | Search term, exact name, prefix path, or /nix/store path |
| `source` | ❌ | `nixos` | `nixos`, `home-manager`, `darwin`, `flakes`, `flakehub`, `nixvim`, `wiki`, `nix-dev`, `noogle`, `nixhub` |
| `type` | ❌ | `packages` | Sub-type: `packages`, `options`, `programs`, `package`, `option`, `flakes`, `ls`, `read` |
| `channel` | ❌ | `unstable` | `unstable`, `stable`, or release like `25.05` |
| `limit` | ❌ | `20` | Max results (1–100, or 1–2000 for flake-inputs/store) |
| `version` | ❌ | `latest` | Package version (only for `action=cache`) |
| `system` | ❌ | `""` | System arch e.g. `x86_64-linux` (only for `action=cache`) |

### Examples

```javascript
// Search for a package
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"search","query":"firefox","limit":5}' })

// Get package details on a specific channel
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"info","query":"git","type":"package","channel":"stable"}' })

// Search NixOS options
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"search","query":"services.postgresql","type":"options","limit":5}' })

// Search Home Manager options
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"search","query":"programs.git","source":"home-manager"}' })

// Check binary cache for a package
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"cache","query":"neovim","system":"x86_64-linux"}' })

// Search the NixOS wiki
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"search","query":"overlays","source":"wiki"}' })
```

## 2. `nixos_nix_versions` — Version History

Get package version history with commit hashes, dates, and attribute paths from NixHub.io.

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `package` | ✅ | — | Package name |
| `version` | ❌ | `""` | Specific version to find |
| `limit` | ❌ | `10` | Max results (1–50) |

### Examples

```javascript
// Recent versions of nodejs
mcp({ server: "nixos", tool: "nixos_nix_versions",
  args: '{"package":"nodejs","limit":5}' })

// Find which commit has a specific version
mcp({ server: "nixos", tool: "nixos_nix_versions",
  args: '{"package":"python3","version":"3.12.4"}' })
```

## Workflow Patterns

### Adding a new package to the NixOS config

1. Search for the package → confirm it exists and get exact attribute name
2. Check binary cache → confirm prebuilt binaries are available
3. Check `unfree.nix` → if proprietary, add it there
4. Add to the appropriate host config or `common.nix`

```
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"search","query":"ripgrep"}' })

mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"cache","query":"ripgrep","system":"x86_64-linux"}' })
```

### Finding the right NixOS option

1. Search options by keyword
2. Get details on the specific option

```
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"search","query":"networking firewall","type":"options"}' })

mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"info","query":"networking.firewall.enable","type":"option"}' })
```

### Researching a package version

1. Check current version in channel
2. Look up version history if you need a specific version or want to know when something was added

```
mcp({ server: "nixos", tool: "nixos_nix",
  args: '{"action":"info","query":"firefox","type":"package"}' })

mcp({ server: "nixos", tool: "nixos_nix_versions",
  args: '{"package":"firefox","limit":5}' })
```

## Gotchas

- **`browse` is limited**: Only works with `home-manager`, `darwin`, `nixvim`, and `noogle` sources. For NixOS options, use `action=search` with `type=options`.
- **`flake-inputs` can timeout**: Evaluating large flakes is expensive. If it times out, fall back to reading `flake.nix` directly.
- **Channel defaults to `unstable`**: If you need the current stable release, explicitly set `channel=stable`.
- **Version history is from NixHub**: The `nixos_nix_versions` tool uses NixHub.io data, which may lag slightly behind the current nixpkgs HEAD.
- **Training data is stale**: Always prefer these tools over guessing package names, versions, or option signatures from memory.
- **Omit unused parameters**: Don't pass empty strings for optional parameters — just omit them.
