{
  config,
  lib,
  pkgs,
  ...
}: {
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;

    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/bluetooth.lua.d/51-bluez-config.lua" ''
          bluez_monitor.properties = {
            ["bluez5.enable-sbc-xq"] = true,
            ["bluez5.enable-msbc"] = true,
            ["bluez5.enable-hw-volume"] = true,
            ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
          }
        '')
      ];
    };
  };

  #  TODO: improve active-audio detection first
  #  systemd.user.services.volume-decay = {
  #    unitConfig = {
  #      Description = "Volume decay service";
  #      After = "pipewire.service";
  #    };
  #
  #    serviceConfig = {
  #      Type = "oneshot";
  #      ExecStart = let
  #        script = pkgs.writeShellScript "volume-decay" ''
  #          # Check if there are any active audio streams
  #          if ! ${pkgs.wireplumber}/bin/wpctl status | grep -q "RUNNING"; then
  #            ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ .01-
  #          fi
  #        '';
  #      in "${script}";
  #    };
  #  };
  #  systemd.user.timers.volume-decay = {
  #    wantedBy = [ "timers.target" ];
  #    partOf = [ "volume-decay.service" ];
  #    unitConfig = {
  #      Description = "Timer for volume decay";
  #    };
  #    timerConfig.OnCalendar = "minutely";
  #  };

  ########################################
  # Packages
  ########################################
  nixpkgs.overlays = [(self: super: {})];

  environment.systemPackages = with pkgs;
  with config.boot.kernelPackages; [
    # Sound Infrastructure
    alsa-utils
    # TODO: broken 2025-01-03 carla
    cmus
    pavucontrol
    pamixer
    pulsemixer
    wireplumber

    # Effects
    easyeffects
    jamesdsp

    # Sound Plugins
    # TODO: broken: distrho
    swh_lv2

    # Bluetooth audio
    bluez
  ];

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez5-experimental;
    settings = {
      # Experimental D-Bus interface (e.g.: integration with UPower).
      General.Experimental = true;
      # To save some power.
      Policy.AutoEnable = false;
    };
  };
  services.pulseaudio.enable = false;

  environment.variables = with lib;
    listToAttrs (map (type:
      nameValuePair "${toUpper type}_PATH" [
        "$HOME/.${type}"
        "$HOME/.nix-profile/lib/${type}"
        "/run/current-system/sw/lib/${type}"
      ]) ["dssi" "ladspa" "lv2" "lxvst" "vst" "vst3"]);
}
