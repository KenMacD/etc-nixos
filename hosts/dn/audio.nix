{ config, lib, pkgs, ... }: {

  sound.enable = false;

  security.rtkit.enable = true; # for pipewire

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    # Update headroom (would be nice if only the 1 config could change
    media-session.config.alsa-monitor = {
      "rules" = [
        {
          "matches" = [{ "device.name" = "~alsa_card.*"; }];
          "actions" = {
            "update-props" = {
              "api.alsa.use-acp" = true;
              "api.acp.auto-port" = false;
              "api.acp.auto-profile" = false;
            };
          };
        }
        {
          "matches" = [
            { "node.name" = "~alsa_input.*"; }
            { "node.name" = "~alsa_output.*"; }
          ];
          "actions" = {
            "update-props" = {
              "node.pause-on-idle" = false;
              "api.alsa.headroom" = 16384;
            };
          };
        }
      ];
    };
    jack.enable = true;
    pulse.enable = true;
    config.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 44100;
        "default.clock.allowed-rates" =
          [ 44100 48000 88200 96000 176400 192000 384000 ];
      };
    };
  };

  ########################################
  # Packages
  ########################################
  nixpkgs.overlays = [ (self: super: { }) ];

  environment.systemPackages = with pkgs;
    with config.boot.kernelPackages; [
      # Sound Infrastructure
      alsa-utils
      carla
      cmus
      pavucontrol
      pamixer
      pulseaudio
      pulseeffects-pw
      pulsemixer

      # Sound Plugins
      lsp-plugins
      rnnoise-plugin
      distrho
      swh_lv2
      calf
    ];

  environment.variables =
    (with lib;
    listToAttrs (
      map
        (
          type: nameValuePair "${toUpper type}_PATH"
            ([ "$HOME/.${type}" "$HOME/.nix-profile/lib/${type}" "/run/current-system/sw/lib/${type}" ])
        )
        [ "dssi" "ladspa" "lv2" "lxvst" "vst" "vst3" ]
    ));
}
