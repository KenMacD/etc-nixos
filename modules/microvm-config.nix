{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.microvm-config;
in {
  # https://microvm-nix.github.io/microvm.nix/routed-network.html
  options.microvm-config = {
    enable = mkEnableOption "Enable microvm support";
    maxVMs = lib.mkOption {
      type = lib.types.int;
      default = 32;
      description = "The maximum number of VM networks to create.";
    };
    externalInterface = lib.mkOption {
      type = lib.types.str;
      description = "External network interface to route to the internet.";
    };
  };

  config = mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.network.networks = builtins.listToAttrs (
      map (index: {
        name = "30-vm${toString index}";
        value = {
          matchConfig.Name = "vm${toString index}";
          # Host's addresses
          address = [
            "10.37.${toString index}.254/32"
            "fd37:${toHexString index}::ffff/128"
          ];
          # Setup routes to the VM
          routes = [
            {
              Destination = "10.37.${toString index}.1/32";
            }
            {
              Destination = "fd37:${lib.toHexString index}::1/128";
            }
          ];
          # Enable routing
          networkConfig = {
            IPv4Forwarding = true;
            IPv6Forwarding = true;
          };
        };
      }) (lib.genList (i: i + 1) cfg.maxVMs)
    );
    networking.nat = {
      enable = true;
      internalIPs = ["10.37.0.0/16"];
      externalInterface = cfg.externameInterface;
    };
  };
}
