{
  pkgs,
  lib,
  ...
}: {
  home-manager.users.kenny = {
    services.opensnitch-ui.enable = true;
  };

  services.opensnitch = {
    enable = true;
    rules = with pkgs;
      lib.mkMerge [
        {
          signal = lib.snitchAllowPath "${lib.getBin signal-desktop-bin}/lib/signal-desktop/signal-desktop";
          keybase = lib.snitchAllowPath "${lib.getBin keybase}/bin/keybase";
          kbfs = lib.snitchAllowPath "${lib.getBin kbfs}/bin/kbfsfuse";
          nix = lib.snitchAllowPath "${lib.getBin nix}/bin/nix";
          firefox = lib.snitchAllowPath "${lib.getBin firefox}/lib/firefox/firefox";
          systemd-networkd = lib.snitchAllowPath "${lib.getBin pkgs.systemd}/lib/systemd/systemd-networkd";
        }
        (lib.opensnitch.mkSimpleRules [
          {
            name = "Local DNS";
            ip = "127.0.0.53";
            port = 53;
          }
          {
            name = "Allow Systemd DNS";
            process = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-resolved";
            port = 53;
          }
          {
            name = "Allow NTP";
            process = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-timesyncd";
            protocol = "udp";
            port = 123;
          }
          {
            name = "Allow Avahi";
            process = "${lib.getBin pkgs.avahi}/bin/avahi-daemon";
            protocol = "udp";
            port = 5353;
          }
          {
            name = "Allow Zerotier";
            process = "${lib.getBin zerotierone}/bin/zerotier-one";
            protocol = "udp";
          }
          {
            name = "Allow Keybase";
            process = "${lib.getBin keybase}/bin/keybase";
          }
        ])
      ];
  };
}
