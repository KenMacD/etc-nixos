{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.sway-desktop;
in {
  options.programs.sway-desktop = {
    enable = mkEnableOption "Enable my sway desktop config";
  };

  config = mkIf cfg.enable {
    programs.sway = {
      enable = true;
      extraPackages = with pkgs; [
        cmst
        grim # screenshot
        libinput
        mako # notifications (tiramisu?)
        papirus-icon-theme
        slurp # select area for screenshot
        swayidle
        swaylock
        tofi
        waybar
        wl-clipboard
        wofi
        xwayland

        glfw-wayland
        glew
        qt5.qtwayland

        polkit-kde-agent

        gtk-engine-murrine
        gtk_engines
        gsettings-desktop-schemas
        lxappearance
        adwaita-icon-theme

        # Display profiles
        kanshi
        wdisplays

        # Clipboard test
        copyq

        # TODO: needed?
        libportal-qt5

        # Test gamma adjust
        wl-gammarelay-rs

        # Systray programs
        blueman
        networkmanagerapplet
        udiskie
        wpa_supplicant_gui
      ];

      extraSessionCommands = ''
        export SDL_VIDEODRIVER="wayland"
        export QT_QPA_PLATFORM="wayland"
        export QT_WAYLAND_DISABLE_WINDOWDECORATIONS="1"
        export _JAVA_AWT_WM_NONREPARENTING="1"
      '';
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
    };

    # Start tray services
    environment.etc."sway/config.d/desktop.conf".source = pkgs.writeText "desktop.conf" ''
      # seat seat0 xcursor_theme Adwaita 24
      exec ${pkgs.blueman}/bin/blueman-applet
      # exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
      exec ${pkgs.udiskie}/bin/udiskie --tray
      exec ${pkgs.wpa_supplicant_gui}/bin/wpa_gui -q -t
    '';

    programs.waybar.enable = true;
    services.blueman.enable = true;

    # glib-networking required for TLS for programs like freerdp
    services.gnome.glib-networking.enable = true;
  };
}
