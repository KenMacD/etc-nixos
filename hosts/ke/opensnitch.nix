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
          firefox = lib.snitchAllowPath "${lib.getBin firefox}/lib/firefox/firefox";
          kbfs = lib.snitchAllowPath (lib.getExe' kbfs "kbfsfuse");
          keybase = lib.snitchAllowPath (lib.getExe keybase);
          nix = lib.snitchAllowPath (lib.getExe nix);
          signal = lib.snitchAllowPath "${lib.getBin signal-desktop-bin}/lib/signal-desktop/signal-desktop";
          systemd-networkd = lib.snitchAllowPath "${lib.getBin pkgs.systemd}/lib/systemd/systemd-networkd";
        }
        (lib.opensnitch.mkSimpleRules [
          {
            name = "Local DNS";
            ip = "127.0.0.53";
            port = 53;
          }
          {
            name = "Allow Avahi";
            process = lib.getExe' avahi "avahi-daemon";
            protocol = "udp";
            port = 5353;
          }
          {
            name = "Allow Fwupd Updates";
            process = lib.getExe' fwupd "fwupdmgr";
            host = "cdn.fwupd.org";
            protocol = "tcp";
            port = 443;
          }
          {
            name = "Allow Keybase";
            process = lib.getExe keybase;
          }
          {
            name = "Allow msmtp magadu";
            process = lib.getExe msmtp.binaries;
            host = "smtp.migadu.com";
            protocol = "tcp";
            port = 587;
          }
          {
            name = "Allow msmtp google";
            process = lib.getExe msmtp.binaries;
            host = "smtp.gmail.com";
            protocol = "tcp";
            port = 587;
          }
          {
            name = "Allow NTP";
            process = "${lib.getBin systemd}/lib/systemd/systemd-timesyncd";
            protocol = "udp";
            port = 123;
          }
          {
            name = "Allow Systemd DNS";
            process = "${lib.getBin systemd}/lib/systemd/systemd-resolved";
            port = 53;
          }
          {
            name = "Allow Zerotier";
            process = lib.getExe' zerotierone "zerotier-one";
            protocol = "udp";
          }
        ])
      ];
  };
}
