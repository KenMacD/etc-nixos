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

  # ? Should set ?
  # environment.variables = {
  #   QT_QPA_PLATFORM = "wayland;xcb";
  # };
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

        glfw
        glew
        # TODO: needed, and if so, use qt6? qt5.qtwayland

        kdePackages.polkit-kde-agent-1

        gtk-engine-murrine
        gtk_engines
        gsettings-desktop-schemas
        lxappearance
        adwaita-icon-theme

        # Display profiles
        kanshi
        shikane
        wdisplays

        # Clipboard test
        copyq

        # TODO: needed?
        # TODO: needed, and if so use qt6? libportal-qt5

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

    # Start shikane
    systemd.user.services.shikane = {
      description = "shikane - dynamic output configuration";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${pkgs.shikane}/bin/shikane";
        Restart = "on-failure";
      };
    };

    # Start tray services
    environment.etc."sway/config.d/desktop.conf".source = pkgs.writeText "desktop.conf" ''
      # seat seat0 xcursor_theme Adwaita 24
      exec ${pkgs.blueman}/bin/blueman-applet
      # exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
      exec ${pkgs.udiskie}/bin/udiskie --tray
      # Start manually when needed: exec ${pkgs.wpa_supplicant_gui}/bin/wpa_gui -q -t

      # Call after sway is started to keep uwsm from killing
      # exec ${pkgs.uwsm}/bin/uwsm finalize
    '';

    programs.waybar.enable = true;
    programs.uwsm.enable = true; # sets graphical-session.target
    programs.uwsm.waylandCompositors = {};
    services.blueman.enable = true;

    # glib-networking required for TLS for programs like freerdp
    services.gnome.glib-networking.enable = true;
  };
}
