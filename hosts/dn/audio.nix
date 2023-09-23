{
  config,
  lib,
  pkgs,
  ...
}: {
  security.rtkit.enable = true; # for pipewire
  services.pipewire.wireplumber.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
  };

  ########################################
  # Packages
  ########################################
  nixpkgs.overlays = [(self: super: {})];

  environment.systemPackages = with pkgs;
  with config.boot.kernelPackages; [
    # Sound Infrastructure
    alsa-utils
    carla
    cmus
    pavucontrol
    pamixer
    pulseaudio
    easyeffects
    pulsemixer

    # Sound Plugins
    distrho
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

  environment.variables = with lib;
    listToAttrs (map (type:
      nameValuePair "${toUpper type}_PATH" [
        "$HOME/.${type}"
        "$HOME/.nix-profile/lib/${type}"
        "/run/current-system/sw/lib/${type}"
      ]) ["dssi" "ladspa" "lv2" "lxvst" "vst" "vst3"]);
  environment.etc = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
      bluez_monitor.properties = {
        ["bluez5.enable-sbc-xq"] = true,
        ["bluez5.enable-msbc"] = true,
        ["bluez5.enable-hw-volume"] = true,
        ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
      }
    '';
  };
}
