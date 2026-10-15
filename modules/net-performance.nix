{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.networking.performance;
in {
  # Opt-in tuning (https://wiki.archlinux.org/title/Sysctl#Improving_performance):
  # only the two settings with real desktop impact — BBR + TCP MTU probing.
  # Skipped: somaxconn (no-op, kernel default since 5.4), tcp_sack (already
  # default), cake qdisc (only pays off with per-interface bandwidth shaping).
  options.networking.performance = {
    enable = mkEnableOption "network performance tuning (BBR congestion control + TCP MTU probing)";

    # SO_KEEPALIVE sockets only: detects dead peers in ~140s instead of ~2h20m
    # and keeps NAT bindings alive. Most useful on laptops / flaky, NATed links.
    keepalive = mkOption {
      type = types.bool;
      default = false;
      description = "Lower TCP keepalive timers (80s idle, 10s interval, 6 probes) for faster dead-peer detection.";
    };

    # Client side (1) is the kernel default; 3 adds the server side, which
    # only matters for apps requesting TCP_FASTOPEN on listening sockets.
    tcpFastOpen = mkOption {
      type = types.bool;
      default = false;
      description = "Enable TCP Fast Open for both client and server (net.ipv4.tcp_fastopen = 3).";
    };
  };

  config = mkIf cfg.enable {
    # bbr autoloads tcp_bbr on write; kernelModules makes boot deterministic.
    boot.kernelModules = ["tcp_bbr"];

    boot.kernel.sysctl =
      {
        # BBR: better throughput/latency than cubic on lossy or high-latency
        # paths, benign on LAN. Local TCP only, not forwarded traffic.
        "net.ipv4.tcp_congestion_control" = "bbr";

        # PLPMTU conservative mode: probe (rather than silently fail) on ICMP
        # black holes. Useful behind tunnels/VPNs/PPPoE.
        "net.ipv4.tcp_mtu_probing" = 1;
      }
      // optionalAttrs cfg.tcpFastOpen {
        "net.ipv4.tcp_fastopen" = 3;
      }
      // optionalAttrs cfg.keepalive {
        "net.ipv4.tcp_keepalive_time" = 80;
        "net.ipv4.tcp_keepalive_intvl" = 10;
        "net.ipv4.tcp_keepalive_probes" = 6;
      };
  };
}
