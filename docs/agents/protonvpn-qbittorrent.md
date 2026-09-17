# ProtonVPN network namespace for qBittorrent (host `r1pro`)

How the per-service VPN setup on r1pro works, and how to verify it is still
fail-close and that NAT-PMP port forwarding is still functioning.

All verification commands run **on r1pro** (ssh in; `sudo` is passwordless for
kenny). The config lives in `hosts/r1pro/configuration.nix` — search for
"ProtonVPN network namespace".

## Architecture

```
internet ──► Proton server (79.135.104.99:51820)
                 │ NAT-PMP: forwards public port → tunnel
                 ▼
      root namespace                protonvpn namespace
      ┌─────────────────┐          ┌──────────────────────────────┐
      │ protonvpn0 (wg) │─ moved ─►│ protonvpn0  10.2.0.2/32      │
      │ (wg UDP socket  │  into ns │ default route ─► protonvpn0  │
      │  stays here)    │          │ veth-protonvpn0 192.168.200.2│
      │ veth-protonvpn  │◄─ /30 ──►│                              │
      │ 192.168.200.1   │          │ qbittorrent-nox (WebUI 59933)│
      │ nginx ──────────┼──────────┼► 192.168.200.2:59933         │
      └─────────────────┘          └──────────────────────────────┘
```

Services:

- **`protonvpn.service`** (oneshot, RemainAfterExit) — creates the `protonvpn`
  netns, creates the WireGuard interface `protonvpn0` in the *root* namespace
  (so its UDP socket can reach the endpoint via the physical uplink), then
  moves it into the namespace and configures it. Also creates the /30 veth
  pair for nginx → WebUI. Idempotency check requires BOTH links to exist;
  a partial namespace from a failed start is torn down and rebuilt.
- **`qbittorrent.service`** — the standard NixOS module, joined into the
  namespace via `NetworkNamespacePath=/run/netns/protonvpn`, `bindsTo` the
  setup service. `PrivateUsers` is force-disabled: setns(2) into a root-owned
  netns needs CAP_SYS_ADMIN in the init userns; a private user namespace
  can never have it → guaranteed EPERM. The module's other sandboxing
  (empty capability set, ProtectSystem, seccomp, …) still applies.
  DNS inside the namespace: `/etc/resolv.conf` is replaced (TemporaryFileSystem
  + BindReadOnlyPaths) with a file pointing at Proton's resolver `10.2.0.1`,
  reachable only through the tunnel.
- **`protonvpn-portfwd.service`** — runs inside the namespace, renews a
  NAT-PMP lease from Proton's gateway `10.2.0.1` every 45s (120s lifetime),
  and pushes the assigned port to qBittorrent via the WebUI API
  (`/api/v2/app/setPreferences {"listen_port": N}`). WebUI auth is bypassed
  for the veth subnet via `WebUI\AuthSubnetWhitelist` in qBittorrent.conf.
  On failure it retries without touching the port.

### Why it is fail-close

The namespace has exactly two routes: `default dev protonvpn0` and the
`192.168.200.0/30` veth route. **No route to the LAN or uplink exists**, so
if the tunnel drops, traffic fails instead of escaping. DNS fails closed the
same way. No iptables/policy-routing rules are involved — the property is
structural and survives any routing-table changes outside the namespace.

### Key facts

| Thing | Value |
|---|---|
| Namespace / interfaces | ns `protonvpn`; wg `protonvpn0`; veth `veth-protonvpn` (host .1) / `veth-protonvpn0` (ns .2) |
| Tunnel | Proton wg endpoint 79.135.104.99:51820, address 10.2.0.2/32, gateway/DNS 10.2.0.1 |
| Private key | sops secret `protonvpn-wg-key` in `hosts/r1pro/secrets.yaml` (sops-nix fails the **build** if the key is missing) |
| WebUI | qBittorrent binds 192.168.200.2:59933 (NOT loopback); nginx vhost `qbittorrent.home.macdermid.ca` proxies to it |
| App-managed config | `/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf` — qBittorrent rewrites it on exit; **stop the service before editing** |

## Verification

### 1. Service health

```sh
systemctl is-active protonvpn.service qbittorrent.service protonvpn-portfwd.service
```

Expect three `active`. (`ip netns list` will also show podman `netns-*`
entries and `romania` — that one belongs to `namespaced-openvpn-romania`,
unrelated.)

### 2. qBittorrent is inside the namespace

```sh
sudo ip netns pids protonvpn
ps -o user,cmd -p <pids>
```

Expect `qbittorrent-nox` and the portfwd loop; nothing else.

### 3. Tunnel is handshaking

```sh
sudo ip netns exec protonvpn wg show protonvpn0
```

`latest handshake` must be under ~3 minutes; transfer counters increasing.

### 4. Fail-close invariant: routes

```sh
sudo ip -n protonvpn route
```

MUST be exactly:

```
default dev protonvpn0 scope link
192.168.200.0/30 dev veth-protonvpn0 proto kernel scope link src 192.168.200.2
```

Anything else — especially a second default or any LAN/uplink subnet — is a
regression.

### 5. Exit IP differs from the host

```sh
sudo ip netns exec protonvpn curl -4 -s --max-time 10 zx2c4.com/ip  # Proton IP
curl -4 -s --max-time 10 zx2c4.com/ip                               # home IP
```

The two must differ. (This also proves in-namespace DNS works — the hostname
resolved through Proton's resolver.)

### 6. Kill-switch test (the important one)

```sh
sudo ip -n protonvpn link set protonvpn0 down
sudo ip netns exec protonvpn curl -4 -s --max-time 5 zx2c4.com/ip
sudo systemctl restart protonvpn.service
systemctl is-active qbittorrent.service
```

The curl **must fail** (empty reply / network unreachable). If it returns an
IP — especially the home IP from step 5 — that is a leak: stop
`qbittorrent.service` immediately and debug. The restart tears down and
rebuilds the namespace; qBittorrent auto-restarts via `bindsTo`. The NAT-PMP
lease lapses within ~2 minutes and is re-leased automatically.

### 7. Port forwarding is alive

```sh
journalctl -u protonvpn-portfwd.service -n 20 --no-pager -o cat   # want: "protonvpn: forwarded port NNNNN"
sudo grep -oP 'Session\\Port=\K[0-9]+' /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
sudo ip netns exec protonvpn curl -s http://192.168.200.2:59933/api/v2/app/preferences | grep -oP '"listen_port":\K[0-9]+'
```

All three values must match. Watch for `command not found` in the journal:
the unit's `path` *replaces* the service PATH (NixOS appends coreutils/grep/
sed but NOT gawk) — if the script grows new command dependencies, add them
there.

### 8. External inbound test (run from a different host)

From any machine **outside** the tunnel (e.g. ke, a laptop, a VPS) — not
r1pro itself:

```sh
timeout 15 bash -c 'echo > /dev/tcp/<proton-exit-ip>/<forwarded-port>' && echo OPEN
```

Use the exit IP and port from steps 5 and 7. `OPEN` proves the full chain:
internet → Proton → NAT-PMP forward → tunnel → namespace → qBittorrent.
qBittorrent announces the port to trackers automatically, so peers see the
client as connectable while the lease is maintained.

### 9. WebUI

`https://qbittorrent.home.macdermid.ca` should return 200 through nginx
(`curl -sk -o /dev/null -w '%{http_code}' --resolve
qbittorrent.home.macdermid.ca:443:127.0.0.1 https://qbittorrent.home.macdermid.ca`
on r1pro).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| sops build error: "key 'protonvpn-wg-key' cannot be found" | Secret missing from `hosts/r1pro/secrets.yaml` |
| portfwd journal: `awk: command not found` | Unit `path` replaced PATH — gawk must stay in the list |
| API/WebUI calls from the namespace return 403 | `WebUI\AuthSubnetWhitelist` lost `192.168.200.0/30` |
| WebUI unreachable via nginx | Check `WebUI\Address=192.168.200.2` in qBittorrent.conf (edit only while the service is stopped) |
| protonvpn.service fails with "add netns: file exists" | Stale namespace — `sudo ip netns del protonvpn` and restart; the start script also self-heals this |
| Handshakes OK but transfers stall | Lower MTU (e.g. 1420 → 1350) in the `protonvpn-start` script |
| Forwarded port changed | Proton re-assigns per tunnel session; the updater syncs qBittorrent within ~45s |

## Related files

- `hosts/r1pro/configuration.nix` — ProtonVPN section (services), `services.qbittorrent`, nginx `proxywssAddr` + vhost
- `hosts/r1pro/secrets.yaml` — `protonvpn-wg-key`
- `/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf` (on r1pro, app-managed) — `WebUI\Address`, `WebUI\AuthSubnetWhitelist`, `Session\Port` (written by the updater)
