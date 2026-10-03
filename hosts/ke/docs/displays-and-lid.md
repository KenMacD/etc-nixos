# External Displays & Lid Behavior — `ke`

How the docked display layout and lid behavior are set up on host `ke`
(Lenovo ThinkPad + ThinkPad Universal USB-C Dock **40AY** + 2 × Dell P2418D).
Companion to `dock.md` (dock model / bandwidth / "3rd monitor?" analysis).

---

## TL;DR — current behavior

| Situation | Result |
|---|---|
| Docked, lid **open** | 3 screens: Dell (left) · Dell (right) · eDP-1 (below, centered) |
| Docked, lid **closed** | 2 screens: the two Dells; eDP-1 off. **System stays awake.** |
| Docked, toggle lid | eDP-1 turns off/on instantly via sway `bindswitch`; Dell layout never moves |
| **Undocked**, close lid | **System suspends** (normal laptop behavior) |

One known gap: see [Redock race](#redock-race-lid-closed--re-dock).

---

## How it works (two independent layers)

### Layer 1 — systemd-logind: "stay awake while docked" (logind defaults, no Nix override)

Live values (`busctl get-property … login1.Manager`):

| Property | Value | Applies when |
|---|---|---|
| `HandleLidSwitch` | `suspend` | undocked on battery |
| `HandleLidSwitchExternalPower` | `""` → `lock` | undocked but on AC |
| `HandleLidSwitchDocked` | `ignore` | **docked** (externals + external power detected) |

Precedence is docked → external-power → battery. logind reports `Docked=true`
while the dock is attached (it sees the external displays + AC), so
`HandleLidSwitchDocked=ignore` wins → **closing the lid does nothing at the
system level**. On undock, `Docked=false` + battery → `suspend`.

### Layer 2 — displays: layout (shikane) + lid toggle (sway `bindswitch`)

- **shikane** matches the connected set and applies the `office` profile
  (positions/modes). It re-applies on dock/undock and (re)start.
- **sway `bindswitch`** toggles eDP-1 with the lid (in `~/.config/sway/config`):
  ```
  bindswitch --reload lid:on  output eDP-1 disable
  bindswitch --reload lid:off output eDP-1 enable
  ```
  `--reload` applies the correct state at startup/reload. eDP-1 stays
  *connected* when the lid closes (the panel doesn't disappear), so disabling it
  does not change the connected set and does **not** re-trigger shikane.

**bindswitch is verified working** on this stack (sway 1.12 + wlroots 0.20.2):
under `sway -d` the lid switch event is delivered to sway's input handler
(`sway/input/switch.c:88 … type 0 state 1/0` on close/open) and dispatched to
the binding (`sway/commands/bind.c:621 running command for binding`). An earlier
attempt to use `bindswitch` here was abandoned as "unreliable" — that turned out
to be a **misdiagnosis**: a polling watcher was running concurrently and masked
the result (it kept re-asserting eDP state, so the bindswitch effect was
invisible). The watcher has been removed; `bindswitch` alone handles lid
open/close cleanly and instantly.

### Layout (the `office` profile)

```
   x=0........................2560.......................5120
  +--------------------------+--------------------------+   y=0
  |  Dell  ser …0XYT (LEFT)  |  Dell  ser …0CCT (RIGHT) |   2560x1440 each
  +--------------------------+--------------------------+   y=1440
                 +----------------------+
                 |   eDP-1  1920x1200   |   (laptop, centered below)
                 +----------------------+
```

The two Dells are matched **by serial** (their DP connector names renumber
across hotplugs — the sway config's commented `#output DP-3..DP-7` lines show
this). `eDP-1` is matched **by name** (`n=eDP-1`), which is stable.

---

## Redock race (lid closed + re-dock)

`bindswitch` is **edge-triggered** — it fires only on a lid open/close event.
On a **re-dock**, shikane re-applies the `office` profile (a connected-set
change) whose eDP-1 entry is `enable = true`, so eDP-1 gets re-enabled **even
if the lid is shut**. Because no lid event occurs, bindswitch does not re-fire,
and eDP-1 stays on (phantom screen at 1600,1440) until the next lid toggle.

This is the only known gap. Options if it matters:

- toggle the lid once after redocking (simplest);
- add a shikane `exec` post-apply hook that re-checks the lid (needs the service
  PATH fix below — shikane's unit PATH lacks `swaymsg`/a shell);
- keep a low-frequency poller (e.g. 5–10 s) purely as a backstop.

(Verified: shikane does **not** fight a manual disable during normal operation —
a one-shot `output eDP-1 disable` sticks. The race is specific to the redock
re-apply path.)

---

## Files

### Live dotfiles

| Path | Purpose |
|---|---|
| `~/.config/sway/config` | the `bindswitch lid:on/off` lines (lid → eDP-1) |
| `~/.config/shikane/config.toml` | `office` (3 outputs) + `laptop` (eDP only) profiles; eDP matched by `n=eDP-1` |

### Declarative (this repo — activate with `just switch`)

`hosts/ke/configuration.nix` writes `~/.config/shikane/config.toml` via
`home-manager.users.kenny.xdg.configFile` (ke-specific; the shared
`home-manager/users/kenny.nix` is untouched). The sway config itself stays a
hand-managed dotfile — the `bindswitch` lines live there.

**First-activation caveat:** home-manager refuses to overwrite an existing
`config.toml`, so before the first `just switch`:

```bash
rm ~/.config/shikane/config.toml
just switch
```

(or enable `home-manager.backupFileExtension`).

---

## Alternatives not currently used

- **shikane `exec`** (post-apply hook) — would close the redock race cleanly,
  but shikane's systemd user service has a stripped NixOS `PATH`
  (coreutils/findutils/grep/sed/systemd — no shell, no `swaymsg`) and resolves
  exec via PATH, so commands fail with `ENOENT`. To use it, give the unit a real
  PATH in `modules/sway-desktop.nix` (the module already does this for
  `waybar`):
  ```nix
  systemd.user.services.shikane.environment.PATH =
    lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin";
  ```
- **shikanectl `switch`/`reload`** — its IPC socket wasn't reachable
  (`Connection refused`) under the default path. Not pursued.
- **A polling watcher** (`lid-watch.sh`) — previously used; removed once
  `bindswitch` was confirmed working. Re-introduce at low frequency only as a
  redock-race backstop if the gap above turns out to bite in practice.

---

## Other ideas

- **Manage the sway config declaratively** (currently a hand-edited dotfile).
- **Add a 3rd display** — not possible through this dock (bandwidth; see
  `dock.md`). Use the laptop HDMI, the 2nd USB-C, a USB DisplayLink adapter on
  the dock, or swap to a Thunderbolt 4 dock.

---

## Verification (re-check commands)

```bash
# logind lid policy (docked=ignore, undocked/battery=suspend)
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandleLidSwitch          # "suspend"
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandleLidSwitchDocked    # "ignore"
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager Docked                   # b true (while docked)

# bindswitch loaded
swaymsg -t get_config | jq -r '.config' | grep bindswitch

# current layout + eDP state
swaymsg -t get_outputs | jq -r 'sort_by(.rect.y,.rect.x) | .[] |
  "\(.name) [\(.serial)] @\(.rect.x),\(.rect.y) active=\(.active)"'

# lid state
grep -o 'open\|closed' /proc/acpi/button/lid/LID/state
```

Expected (docked, lid open): DP-6 …0XYT @0,0, DP-7 …0CCT @2560,0, eDP-1
@1600,1440, all `active=true`. Close the lid → eDP-1 `active=false` (instant,
via bindswitch); open → `active=true` again at @1600,1440.
