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
