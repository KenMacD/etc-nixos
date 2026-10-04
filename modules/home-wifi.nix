{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home-wifi;
in {
  options.home-wifi = {
    enable = mkEnableOption "Enable home wifi network setup";
  };

  config = mkIf cfg.enable {
    # Intel LAR firmware ignores `iw reg set` (the wiphy is self-managed): it
    # only adopts a country from beacon Country IEs heard during a scan, and
    # sometimes stays stuck in world (00) mode even after associating.  If the
    # card hasn't resolved a country by boot time, force a fresh unassociated
    # scan + reconnect, which makes the firmware re-evaluate LAR.
    systemd.services.wireless-regdom = {
      description = "Resolve wireless regulatory domain via LAR rescan";
      after =
        ["multi-user.target"]
        ++ map (
          interface: "wpa_supplicant-${interface}.service"
        )
        config.networking.wireless.interfaces;
      path = with pkgs; [iw wpa_supplicant];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "wireless-regdom-lar-nudge" ''
          for dev in ${concatStringsSep " " config.networking.wireless.interfaces}; do
            # Wait (up to 45s) for wpa_supplicant to finish associating.
            for _ in $(seq 1 45); do
              state=$(wpa_cli -i "$dev" status 2>/dev/null | sed -n 's/^wpa_state=//p')
              [ "$state" = "COMPLETED" ] && break
              sleep 1
            done

            phy=$(iw dev "$dev" info 2>/dev/null | awk '/wiphy/ {print "phy" $2; exit}')
            [ -n "$phy" ] || continue

            country=$(iw "$phy" reg get 2>/dev/null | awk '/^country/ {sub(/:.*/, "", $2); print $2; exit}')
            if [ "$country" = "00" ]; then
              echo "$phy stuck in world (00) regdom; forcing rescan to kick LAR"
              wpa_cli -i "$dev" disconnect || true
              sleep 2
              iw dev "$dev" scan ap-force >/dev/null || true
              sleep 2
              wpa_cli -i "$dev" reassociate || true
              sleep 5
              country=$(iw "$phy" reg get 2>/dev/null | awk '/^country/ {sub(/:.*/, "", $2); print $2; exit}')
            fi
            echo "$phy regdom: $country"
          done
        '';
      };
      wantedBy = ["multi-user.target"];
    };

    systemd.network.networks =
      foldl'
      (acc: interface:
        {
          "30-homewifi-${interface}" = {
            matchConfig = {
              Name = interface;
              SSID = "MacDermid";
            };
            networkConfig =
              {
                MulticastDNS = true;
              }
              // (getAttr "40-${interface}" config.systemd.network.networks).networkConfig;
            dhcpV4Config = {
              UseDomains = true;
            };
          };
        }
        // acc)
      {}
      config.networking.wireless.interfaces;
  };
}
