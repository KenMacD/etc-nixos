{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.laptop;
in {
  options.laptop = {
    enable = mkEnableOption "laptop power & battery defaults (upower low-SoC shutdown, fwupd, plus optional thunderbolt/power-profiles-daemon). All values use mkDefault so a host may override any of them.";

    # Thunderbolt / USB4 is not present on every laptop (e.g. older machines).
    thunderbolt = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the Thunderbolt/USB4 management daemon (bolt). Disable on laptops without TBT/USB4 hardware.";
    };

    # power-profiles-daemon needs HWP (intel_pstate active mode) or an ACPI
    # platform_profile; pre-Skylake CPUs (no HWP) cannot run it.
    powerProfiles = mkOption {
      type = types.bool;
      default = true;
      description = "Enable power-profiles-daemon (requires HWP / intel_pstate active mode or an ACPI platform_profile). Disable on older CPUs without HWP.";
    };
  };

  config = mkIf cfg.enable {
    # Emoji, CJK + unicode fallback coverage for graphical hosts
    fonts.enableDefaultPackages = true;

    # Battery protection: warn the user, then perform a clean poweroff at low
    # state-of-charge to protect the cells from deep-discharge degradation.
    # (percentageAction is the level at which criticalPowerAction is taken.)
    # NOTE: thermald is intentionally NOT included here -- on modern HWP CPUs it
    # is redundant, and hosts that want it (e.g. older non-HWP machines) can set
    # services.thermald.enable = true directly.
    services.upower = {
      enable = mkDefault true;
      criticalPowerAction = mkDefault "PowerOff";
      percentageLow = mkDefault 15;
      percentageCritical = mkDefault 10;
      percentageAction = mkDefault 5;
    };

    # Memory tuning. Kernel defaults (NixOS 7.1 config) for reference:
    #   enabled=[madvise]  shmem_enabled=[never]  defrag=[madvise]
    #   khugepaged/max_ptes_none=511  khugepaged/defrag=1  lru_gen/min_ttl_ms=0
    systemd.tmpfiles.rules = [
      # MGLRU: pages resident <1s are not evicted. Anti-thrash guard; the
      # trade is earlier OOM kills under real memory starvation (acceptable
      # here, unlike r1pro). Needs CONFIG_LRU_GEN (default kernel has it).
      "w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000"
      # THP for all anonymous memory, not just madvise() opt-ins. Desktop and
      # VM-RAM responsiveness; pairs with defer+madvise defrag below.
      "w /sys/kernel/mm/transparent_hugepage/enabled - - - - always"
      # THP for tmpfs/shmem pages only when madvised (opt-in, like the default
      # anon policy).
      "w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - advise"
      # With enabled=always: sync compaction only for madvised regions; other
      # regions are collapsed in the background by khugepaged instead of
      # stalling the faulting process. (khugepaged/defrag stays at default 1.)
      "w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
      # Only collapse fully-populated regions. Default 511 happily collapses
      # nearly-empty ones (2MB allocated per 4KB used), which is the memory
      # bloat THP is criticized for; 0 caps that.
      "w /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 0"
    ];

    # Runtime power profiling via HWP. No-op on CPUs without HWP (disable via
    # laptop.powerProfiles = false on such hosts).
    services.power-profiles-daemon.enable = mkDefault cfg.powerProfiles;

    # Thunderbolt / USB4 dock management (disable via laptop.thunderbolt = false
    # on hosts without TBT/USB4 hardware).
    services.hardware.bolt.enable = mkDefault cfg.thunderbolt;

    # Firmware updates for physical hardware
    services.fwupd.enable = mkDefault true;
  };
}
