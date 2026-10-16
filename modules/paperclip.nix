# Paperclip (AI agent orchestrator) server, upstream OCI image.
# Full architecture, maintenance, and runbook: docs/paperclip.md
{
  config,
  pkgs,
  ...
}: let
  # Pin a release tag plus the digest
  version = "2026.1005.0";
  # Digest of 'ghcr.io/paperclipai/paperclip:2026.1005.0' (linux/amd64).
  imageDigest = "sha256:047336965a43b33989634706af87c69f8ef93da2fffd4b1c364e2a93d50b8a44";
  dbuser = "paperclip";
  dbname = "paperclip";
  ociBackend = config.virtualisation.oci-containers.backend;

  # Ambient model-picker configs. The pickers discover models by shelling out
  # (`opencode models`, `pi --list-models`) with a bare env; runs instead get
  # providers injected from PAPERCLIP_OPENCODE_PROVIDERS /
  # PAPERCLIP_PI_PROVIDERS in the sops env file. Ids are litellm aliases —
  # new model family = new alias in litellm + a line here.
  opencodeConfig = pkgs.writeText "paperclip-opencode.json" (builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.litellm = {
      npm = "@ai-sdk/openai-compatible";
      options = {
        baseURL = "http://host.containers.internal:3005/v1";
        apiKey = "{env:LITELLM_API_KEY}";
      };
      models = {
        glm = {};
        qwen = {};
        glm-flash = {};
        qwen-flash = {};
        deepseek-flash = {};
      };
    };
  });

  # Hermes lane: providers come from $HERMES_HOME/config.yaml; `key_env`
  # points at the container env, so the file carries no secret and needs no
  # generation service (unlike pi's template above).
  hermesHome = pkgs.writeTextDir "config.yaml" ''
    custom_providers:
      - name: litellm
        base_url: http://host.containers.internal:3005/v1
        key_env: LITELLM_API_KEY
        models:
          - glm
          - glm-flash
          - qwen
          - qwen-flash
          - deepseek-flash
    model:
      provider: zai
      default: glm-5.3-flash
  '';

  # pi quirks (all verified empirically): `models` must be an ARRAY (a map
  # gets the provider silently dropped → "Configured Pi model is unavailable"
  # at run time — applies to PAPERCLIP_PI_PROVIDERS in sops too), and custom
  # providers need the apiKey INLINE (pi does no env expansion there and
  # ignores auth.json). Hence a template rendered by paperclip-pi-config.
  litellmModel = id: name: {
    inherit id name;
    contextWindow = 200000;
    maxTokens = 128000;
  };
  piModelsTemplate = pkgs.writeText "pi-models.json.tmpl" (builtins.toJSON {
    providers.litellm = {
      baseUrl = "http://host.containers.internal:3005/v1";
      apiKey = "__LITELLM_API_KEY__";
      api = "openai-completions";
      models = [
        (litellmModel "glm" "GLM (litellm)")
        (litellmModel "qwen" "Qwen (litellm)")
        (litellmModel "glm-flash" "GLM Flash (litellm)")
        (litellmModel "qwen-flash" "Qwen Flash (litellm)")
        (litellmModel "deepseek-flash" "DeepSeek Flash (litellm)")
      ];
    };
  });
in {
  # System PostgreSQL (shared instance; postgresqlBackup covers it). The
  # container reaches it via host.containers.internal; TCP/5432 + podman0
  # firewall come from modules/litellm.nix.
  services.postgresql = {
    ensureDatabases = [dbname];
    ensureUsers = [
      {
        name = dbuser;
        ensureDBOwnership = true;
        # Password set manually on first deploy; credential lives in
        # DATABASE_URL (sops).
      }
    ];
  };

  services.postgresql.authentication = ''
    host paperclip paperclip 10.88.0.0/16 scram-sha-256
  '';

  # DATABASE_URL + BETTER_AUTH_SECRET (environment file).
  sops.secrets.paperclip = {};

  # PAPERCLIP_PUBLIC_URL is templated so the tailnet domain never lands in
  # the world-readable Nix store (only r1pro imports this module and
  # declares the tailnet-domain secret).
  sops.templates.paperclip-env = {
    mode = "0400";
    content = ''
      ${config.sops.placeholder.paperclip}
      PAPERCLIP_PUBLIC_URL=https://paperclip.${config.sops.placeholder.tailnet-domain}
    '';
  };

  virtualisation.oci-containers.containers.paperclip = {
    image = "ghcr.io/paperclipai/paperclip:${version}@${imageDigest}";
    ports = ["127.0.0.1:3100:3100"];
    environment = {
      # Ambient picker configs mount OUTSIDE /paperclip: the entrypoint
      # chowns /paperclip on boot and dies on read-only files there. pi
      # itself is npm-installed into the volume (image bundles codex, claude,
      # opencode, gemini, kimi — not pi).
      OPENCODE_CONFIG = "/etc/paperclip-opencode.json";
      PI_CODING_AGENT_DIR = "/etc/pi-agent";
      HERMES_HOME = "/etc/hermes-home";
      PAPERCLIP_PI_COMMAND = "/paperclip/.npm-global/bin/pi";
      # .local/bin: hermes-agent (uv tool install, like the npm pi below)
      PATH = "/paperclip/.local/bin:/paperclip/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
    };
    environmentFiles = [
      config.sops.templates.paperclip-env.path
    ];
    volumes = [
      # Uploads, local secrets key, agent workspaces; named volume so the
      # entrypoint's chown works on first boot. Embedded PGlite stays unused
      # (DATABASE_URL → system postgres above).
      "paperclip-data:/paperclip"
      "${opencodeConfig}:/etc/paperclip-opencode.json:ro"
      "/run/paperclip-pi/models.json:/etc/pi-agent/models.json:ro"
      "/run/paperclip-hermes:/etc/hermes-home"
    ];
  };

  systemd.services = {
    "${ociBackend}-paperclip" = {
      requires = [
        "postgresql.target"
        "paperclip-pi-config.service"
      ];
      after = [
        "postgresql.target"
        "paperclip-pi-config.service"
      ];
    };

    # Render pi's ambient models.json with the litellm key (inline-key quirk,
    # see above).
    "paperclip-pi-config" = {
      description = "Render pi models.json with the litellm key";
      before = ["${ociBackend}-paperclip.service"];
      wantedBy = ["${ociBackend}-paperclip.service"];
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = [
          "paperclip-pi"
          "paperclip-hermes"
        ];
        RuntimeDirectoryMode = "0755";
        RemainAfterExit = true;
      };
      script = let
        secretsFile = config.sops.secrets.paperclip.path;
      in ''
        key=$(sed -n 's/^LITELLM_API_KEY=//p' "${secretsFile}" | head -1 | tr -d '\r')
        if [ -z "$key" ]; then
          echo "LITELLM_API_KEY not found in ${secretsFile}" >&2
          exit 1
        fi
        sed "s|__LITELLM_API_KEY__|$key|g" "${piModelsTemplate}" \
          > /run/paperclip-pi/models.json
        chmod 0644 /run/paperclip-pi/models.json
        # Hermes writes state into HERMES_HOME; the sandboxed task runner
        # is uid 1000 (bwrap spawns inherit the server uid), so the home
        # must stay 1000-owned — the re-own also cleans root leftovers.
        cp "${hermesHome}/config.yaml" /run/paperclip-hermes/config.yaml
        chown -R 1000:1000 /run/paperclip-hermes
        chmod 0700 /run/paperclip-hermes
        chmod 0644 /run/paperclip-hermes/config.yaml
      '';
    };
  };
}
