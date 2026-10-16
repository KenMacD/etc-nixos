# Paperclip (r1pro)

Paperclip (AI agent orchestrator) running as a podman container on r1pro,
using the **system PostgreSQL** (not the embedded one) so the DB lands in the
nightly `postgresqlBackup` dump.

- URL: <https://paperclip.<tailnet>.ts.net> (tailnet only, via
  `tailscale serve --service=svc:paperclip`)
- Module: `modules/paperclip.nix` (imported by `hosts/r1pro/configuration.nix`,
  which also has the `tailscale-serve-paperclip` unit)
- Image: `ghcr.io/paperclipai/paperclip:2026.1005.0@sha256:04733696...`
  (digest-pinned; update = bump `version`/`imageDigest` in the module. Pin the
  point-release tag (e.g. `2026.1005.0`), never `latest`/minor tags — those
  move. The
  other `ghcr.io/paperclipai/agent-runtime-*` images are sandbox images for
  agent harnesses, not the server.)
- Port: `127.0.0.1:3100:3100`
- Volume: named volume `paperclip-data` → `/paperclip` (uploads, local
  secrets key, agent workspaces). NOT included in postgres backups.
- DB: system postgres, db/role `paperclip`, reached from the container via
  `host.containers.internal:5432` (same as litellm). pg_hba line in
  `modules/paperclip.nix`.
- Secret: sops key `paperclip` in `hosts/r1pro/secrets.yaml` — env file with
  `DATABASE_URL` and `BETTER_AUTH_SECRET`, mounted via
  `environmentFiles` (`/run/secrets/paperclip`).

## First-time provisioning (done 2026-09-27)

`ensureUsers`/`ensureDatabases` create the role + DB but cannot set a
password. It was set manually before the first deploy:

```sh
PW=$(sops -d hosts/r1pro/secrets.yaml \
  | sed -n 's/^[[:space:]]*DATABASE_URL=postgres:\/\/paperclip:\([^@]*\)@.*/\1/p')
printf "ALTER ROLE paperclip PASSWORD '%s';\n" "$PW" \
  | ssh r1pro.<tailnet>.ts.net sudo -u postgres psql
```

(`ensureUsers` is idempotent, so this can be re-run after any DB restore.)

## Rotating secrets

Both secrets live in the `paperclip` sops key. Rotation = new value in sops +
apply on the DB (password only) + redeploy/restart.

### Rotate DB password (DATABASE_URL)

```sh
# 1. From the repo (ke):
openssl rand -hex 24                     # new password
sops hosts/r1pro/secrets.yaml            # replace password inside DATABASE_URL

# 2. Update the role BEFORE restarting the container (old pw still valid):
PW=$(sops -d hosts/r1pro/secrets.yaml \
  | sed -n 's/^[[:space:]]*DATABASE_URL=postgres:\/\/paperclip:\([^@]*\)@.*/\1/p')
printf "ALTER ROLE paperclip PASSWORD '%s';\n" "$PW" \
  | ssh r1pro.<tailnet>.ts.net sudo -u postgres psql

# 3. Ship the new secret and restart the app:
just deploy r1pro
ssh r1pro.<tailnet>.ts.net sudo systemctl restart podman-paperclip
```

### Rotate BETTER_AUTH_SECRET

Invalidates all login sessions (users just log in again). Paperclip encrypts
stored provider credentials with a local secrets key inside the
`paperclip-data` volume, not with this secret, so stored integrations
survive.

```sh
openssl rand -hex 32
sops hosts/r1pro/secrets.yaml            # replace BETTER_AUTH_SECRET value
just deploy r1pro
ssh r1pro.<tailnet>.ts.net sudo systemctl restart podman-paperclip
```

## Backups

- DB: `services.postgresqlBackup` (default `backupAll`) dumps all databases
  nightly → paperclip is included (`all.sql.gz`).
- Volume: `paperclip-data` is NOT covered by postgres dumps. If the volume is
  lost, stored provider credentials/uploads go with it. Add the volume path
  (`/var/lib/containers/storage/volumes/paperclip-data/_data`) to a file
  backup, or accept the risk.

## Model access lanes (2026-09-29)

| Lane | Adapter | Models | Key path |
|---|---|---|---|
| z.ai coding plan | `codex_local` | `glm-4.6` … (z.ai ids) | `PAPERCLIP_CODEX_PROVIDERS` + `ZAI_API_KEY` (sops env) |
| litellm gateway | `opencode_local` | `litellm/glm`, `litellm/qwen-flash`, … aliases | `PAPERCLIP_OPENCODE_PROVIDERS` + `LITELLM_API_KEY` (sops env) |
| litellm gateway | `pi_local` | same aliases | `PAPERCLIP_PI_PROVIDERS` + `LITELLM_API_KEY` (sops env) |

litellm is the model hub for the last two lanes: add/alias models in litellm
(spend logs, budgets, version repointing live there), then add one line to
EACH ambient config so the pickers see it:

- opencode picker: `provider.litellm.models` in `modules/paperclip.nix`
  (`opencodeConfig`, mounted at `/etc/paperclip-opencode.json`)
- pi picker: `providers.litellm.models` in `modules/paperclip.nix`
  (`piModelsTemplate` — note pi wants `models` as an ARRAY, not a map)

Runtime provider injection (what runs actually use) comes from the sops env
vars; `{env:VAR}` placeholders in them are expanded by the paperclip server.

pi-specific notes:

- The pi CLI is NOT in the image (codex/claude/opencode/gemini/kimi are). It
  is npm-installed into the volume at `/paperclip/.npm-global`; the container
  env points at it (`PAPERCLIP_PI_COMMAND`, `PATH`). If the volume is ever
  wiped, restore with:
  `podman exec paperclip sh -c 'npm config set prefix /paperclip/.npm-global && npm install -g @mariozechner/pi-coding-agent'`
- pi does NOT expand env refs in models.json and ignores auth.json for custom
  providers — the key must be inline. So the ambient models.json is a nix
  TEMPLATE: `paperclip-pi-config.service` renders it with the sops key into
  `/run/paperclip-pi/models.json` (mounted read-only at
  `/etc/pi-agent/models.json`). Runs bypass this file entirely (managed dir
  from `PAPERCLIP_PI_PROVIDERS` — that sops JSON must use the array `models`
  shape too; pi drops providers whose models is a map).

litellm-specific notes:

- Port dual-binding `127.0.0.1:3005` + `10.88.0.1:3005` (podman0 gateway) in
  `modules/litellm.nix` — loopback-only bindings are unreachable from
  containers; `host.containers.internal:3005` is how paperclip reaches it.
- `LITELLM_DROP_PARAMS=True` on the litellm container — harnesses send
  OpenAI-only params (`max_completion_tokens`, `store`) that the zai upstream
  rejects. (The `litellm_settings` row in the LiteLLM_Config DB table is NOT
  honored by this version; the env var is.)
- Cost display in paperclip shows **$0** for litellm models: opencode/pi
  compute costs from harness-side model pricing metadata, which our gateway
  model entries don't carry. Token counts are tracked; real spend lives in
  litellm (spend logs per virtual key). To get dollars in paperclip, add cost
  fields to the two nix model configs.

## Creating another org (bypassing the onboarding wizard)

The first-run wizard's "Connect a model" step is hardcoded to OpenAI and
Anthropic tiles (`API_KEY_ENV_KEYS` in `ui/src/components/OnboardingWizard.tsx`)
and the visible close button was removed upstream. Since our model access is
env-provided (sops) + custom providers, the wizard has nothing to offer — it
also only creates the org at its FINAL step (with the first-agent hire), so
"back" never commits anything.

Escapes, in order:

1. **Escape key** dismisses the wizard (Radix `onOpenChange` → `handleClose`),
   nothing created. If Escape is swallowed:
2. **Create the org via console** (devtools on the paperclip tab; `name` is
   the only required field):

```js
await fetch("/api/companies", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ name: "My New Org" }),
}).then((r) => r.json());
```

3. **Hire the first agent via console** (direct hire works while the org's
   `requireBoardApprovalForNewAgents` is false; `onboardingFirstAgent: true`
   seeds the chief-of-staff persona). Pick the lane:

```js
// pi via litellm
await fetch("/api/companies/<ORG_ID>/agent-hires", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({
    name: "Chief of Staff",
    role: "general",
    adapterType: "pi_local",
    adapterConfig: {
      model: "litellm/glm-flash",
      networkAllowlist: ["host.containers.internal"],
    },
    onboardingFirstAgent: true,
  }),
}).then((r) => r.json());

// codex via z.ai (NET's original hire)
adapterType: "codex_local",
adapterConfig: { model: "glm-4.6", networkAllowlist: ["api.z.ai"] },
```

4. Reload — the wizard's open-state is client-only, so it stays gone. The new
   org's board shows the **Add Agent** card: the full adapter catalog for any
   further agents. Leave "API Key Provider" unbound for litellm models (those
   7 options are pi's built-in catalog providers; gateway keys arrive via the
   config files above, not a provider slot).

## Health

```sh
curl https://paperclip.<tailnet>.ts.net/api/health
```
