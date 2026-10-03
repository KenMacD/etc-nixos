# Dock & Display Analysis — `ke`

Investigation of the docking-station / external-display setup on host `ke`,
including measured DisplayPort bandwidth and options for adding a third
external monitor.

---

## TL;DR

- **Dock:** Lenovo ThinkPad Universal USB-C Dock, model **40AY** (USB-C
  DisplayPort Alt-Mode class — **not** a Thunderbolt dock).
- **Connection:** plain USB-C with DP Alt-Mode, **Pin Assignment D** (2 DP lanes
  + SuperSpeed USB). **Not** using Thunderbolt/USB4 tunneling.
- **Video link:** DP 1.4 HBR3, **2 lanes** → 16.2 Gbit/s link / **12.96 Gbit/s
  usable**.
- **Current use:** 2 × Dell P2418D @ 2560×1440 @ 60 Hz ≈ **11.6 Gbit/s (~89 %)**
  of the dock's DP link. DSC/FEC off (monitors are DP 1.2, no DSC).
- **Third monitor through the dock:** ❌ not possible (link saturated; no knob to
  force 4-lane; dock has no USB-video chip).
- **Third monitor elsewhere:** ✅ laptop HDMI (independent), 2nd USB-C port
  (own DP link), or a **USB DisplayLink adapter** plugged into the dock (keeps
  one cable).
- **Real upgrade path for full bandwidth on one cable:** a **Thunderbolt 4 /
  USB4 dock**. The laptop already supports TB4 on both USB-C ports.

---

## Hardware

| Component | Detail |
|---|---|
| **Laptop** | ThinkPad, Intel Iris Xe (Raptor Lake-P, "Gen12"), `i915` driver |
| **TB4** | 2× Thunderbolt 4 NHI controllers (`00:0d.2`, `00:0d.3`), both `authorized`, `generation = 4`, security level `user`, `bolt 0.9.8` installed, `iommu_dma_protection = 1` |
| **Dock** | Lenovo ThinkPad Universal USB-C Dock — **model 40AY** (e.g. `40AY0090US` ~90 W). Identified from USB Billboard: `idProduct 0x30a9`, `iProduct "40AY"`, VID `17ef`, SVID `0xFF01` (DP Alt-Mode). |
| **Dock internals** | Synaptics MST branch hub (OUI `90CC24`), Realtek RTL8153 gigabit Ethernet, VIA Labs VL817-class USB 3.1 hubs, Lenovo USB-C Dock audio chip. **No DisplayLink chip.** |
| **External monitors** | 2 × **Dell P2418D**, each 2560×1440 @ 59.951 Hz, 8 bpc RGB, on `DP-6` / `DP-7` (single shared MST link) |
| **Internal** | `eDP-1` BOE 0x0B63, 1920×1200 @ 60 Hz |

### Dock specs (Lenovo 40AY)

- Video: **2 × DisplayPort 1.4 + 1 × HDMI 2.0** (rated up to 3 external monitors:
  2 × 4K@60 + 1 × 4K@30 headline — requires 4-lane DP + DSC, not achievable in
  the current 2-lane Pin-D negotiation)
- Data: 1 × USB-C (10 G), 3 × USB-A 3.1 Gen 2 (10 G, one always-on),
  2 × USB-A 2.0
- Networking: gigabit Ethernet (RTL8153)
- Power: up to 100 W charging
- Class: **USB-C DP Alt-Mode**, **not Thunderbolt**

---

## Why it is NOT using Thunderbolt 4

The laptop's TB4 is fully enabled — the dock just can't use it.

**Laptop side (all good):**

```
/sys/bus/thunderbolt/devices/
  0-0   device_name=Gen12  generation=4  authorized=1   # host TB4 NHI #0
  1-0   device_name=Gen12  generation=4  authorized=1   # host TB4 NHI #1
  domain0  security=user   iommu_dma_protection=1
  domain1  security=user   iommu_dma_protection=1
```

- TB4 controllers present and authorized; security level `user` (managed by
  `bolt`, which is installed).
- Both USB-C ports are TB4-capable.

**Dock side (the limiter):**

- Only the two **host** routers exist. A real TB dock would appear as a remote
  router (e.g. `1-3`). **None present.**
- Dock Billboard advertises SVID **`0xFF01` (DisplayPort Alt-Mode)**, not
  `0x8087` (Thunderbolt).
- Monitors are native `i915` DP connectors (DP Alt-Mode), peripherals are plain
  USB — nothing is tunneled over a 40 G Thunderbolt path.
- TB4 root ports (`00:07.0/.2`) report PCIe `width 0` → no tunnel active.

→ The **40AY is a USB-C dock, not a Thunderbolt dock.** It has no USB4 router,
so even on a TB4 port it falls back to plain USB-C. No BIOS toggle or `boltctl`
command can change that — the capability must live in the dock.

---

## Bandwidth — measured from the kernel

Source: `i915` debugfs (`/sys/kernel/debug/dri/1/...`) + `swaymsg`.

### Link configuration

```
[CONNECTOR:586:DP-6]  TC Port F/TC#3: mode: dp-alt, pin assignment: D, max lanes: 2
[CONNECTOR:589:DP-7]  TC Port F/TC#3: mode: dp-alt, pin assignment: D, max lanes: 2
i915_dp_force_link_rate   = [auto] ... 810000*      # 8.1 Gbit/s per lane = HBR3 (active)
i915_dp_force_lane_count  = [auto] 1 2* 4           # 2 lanes (active)
```

- **Pin Assignment D** = 2 DP lanes + SuperSpeed USB (USB3 retained).
  The dock keeps USB3 alive (Ethernet + hubs), forcing Pin D.
- DP 1.4 HBR3, 2 lanes → 8.1 × 2 = **16.2 Gbit/s link**, ×0.8 (8b/10b) =
  **12.96 Gbit/s usable**.

### Per-monitor payload

Each Dell P2418D @ 2560×1440 @ 60, 24 bpp, pixel clock 241.5 MHz:

- 241.5 MHz × 24 bit = **5.80 Gbit/s** each (≈ 900 PBN / 30 MST slots)

### Utilization

| | Value |
|---|---|
| Both monitors (MST payload) | **~11.6 Gbit/s** (1800 PBN, 60 of 63 MST slots) |
| Dock link capacity | 12.96 Gbit/s |
| **Utilization** | **~89 %** (95 % of MST slots) |
| Headroom remaining | **~1.4 Gbit/s** (3 MST slots) |
| DSC / FEC | off (monitors are DP 1.2, no DSC sink) |

### The separate "data rate" (common confusion)

A USB-C cable carries **independent channels on different pin-groups**, not one
big pipe:

```
host USB-C cable to dock
├── USB 3.x data  .... 10 Gbit/s   ← manual's "data rate" (USB ports + Ethernet)
├── DP Alt-Mode ... 2-lane HBR3 = 12.96 Gbit/s usable  ← drives monitors
├── USB 2.0 ......... 480 Mbit/s   (audio + HID)
└── USB Power Delivery ........... up to 100 W
```

- The manual's "10 Gbit/s" is the **USB data** channel — it does **not** add to
  display bandwidth.
- Video draws only from the DP Alt-Mode lanes, which are already ~89 % full.
- The USB data channel is ~9 Gbit/s idle but the dock has no USB-video chip, so
  it drives no display — that idle bandwidth is what a DisplayLink adapter would
  use.

---

## Can a third monitor be added?

### Through the 40AY dock — ❌ No

- Only **~1.4 Gbit/s** spare on the 2-lane DP link; a 3rd 1440p@60 needs
  ~5.8 Gbit/s (30 MST slots). Won't link.
- No DSC available (P2418D = DP 1.2).
- **No setting to force 4-lane (Pin C).** Pin assignment is decided by the
  USB-C PD controller / UCSI firmware at connect time, kept at Pin D because the
  dock's internal gigabit-Ethernet chip sits on USB3. There is no
  `pin_assignment` sysfs knob; `typec_displayport` isn't even loaded (DP alt-mode
  is handled opaquely by UCSI). `i915_dp_force_lane_count` is downstream of the
  mux and can't override it.
- The dock has no USB-to-video engine (no DisplayLink `17e9`), so its idle USB3
  bandwidth drives no display.

### Elsewhere — ✅ Yes

1. **Laptop HDMI** (easiest): `HDMI-A-1` is a dedicated iGPU TMDS output
   (encoder 1, independent of the dock's DDI TC3), own ~18 Gbit/s (HDMI 2.0),
   free pipe (`pipe D` idle). Direct HDMI, no adapter.
2. **2nd USB-C port**: its own DP Alt-Mode link (independent ~12.96 Gbit/s).
3. **USB DisplayLink adapter plugged into the dock's spare USB port**: renders a
   3rd screen over the idle USB3 bulk channel; outputs HDMI/DP to the monitor;
   **preserves the single host cable**. Trade-offs: some CPU use, fine for
   office/coding/web/video, not for gaming; needs `evdi` + `displaylink` on
   NixOS (out-of-tree module, rebuilds on kernel update).

### Best long-term option — a Thunderbolt 4 dock

The laptop is already TB4-ready. A real TB4/USB4 dock tunnels everything over
the 40 G link (DP up to ~32.4 Gbit/s), so 3 × 1440p60 or 2 × 4K60 fits easily on
one cable. Candidates: Lenovo ThinkPad Thunderbolt 4 Dock (40B0), CalDigit TS4,
OWC Thunderbolt Dock, etc. A TB4 dock will need a one-time `boltctl`
authorization (security level `user`).

---

## Re-verification commands

```bash
# Monitors + modes
swaymsg -t get_outputs

# Dock identity (model from USB Billboard)
sudo lsusb -v -s 003:051 | grep -iE 'iProduct|idProduct|wSVID'

# DP link config (Pin assignment / lanes / link rate)
sudo cat /sys/kernel/debug/dri/1/i915_display_info | grep -iE 'pin assignment|lane|port_clock'
sudo cat /sys/kernel/debug/dri/1/DP-6/i915_dp_force_link_rate
sudo cat /sys/kernel/debug/dri/1/DP-6/i915_dp_force_lane_count

# MST payload table (PBN / slots / dsc per sink)
sudo cat /sys/kernel/debug/dri/1/i915_dp_mst_info

# Thunderbolt topology (host routers only => no TB dock connected)
ls /sys/bus/thunderbolt/devices/

# Connector properties (no root needed)
nix shell nixpkgs#drm_info -c drm_info | less
```

---

## File / config references

- Display layout lives in the Sway config (not in this repo's `hosts/ke/`):
  `~/.config/sway/config` — add a 3rd output block once a 3rd display is
  attached.
- For a future TB4 dock: enable `services.hardware.bolt.enable = true;` (or use
  `boltctl` ad-hoc) so `user`-security TB devices can be authorized.
- For a DisplayLink adapter: add the `evdi` kernel module + a DisplayLink driver
  flake (out-of-tree; rebuilds on kernel update).
