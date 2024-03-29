{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.network.enable = true;

  environment.systemPackages = with pkgs; [
    iw
    wavemon
    wirelesstools
    wpa_supplicant_gui
  ];

  networking.usePredictableInterfaceNames = true;
  networking.wireless.interfaces = [
    "wlp0s20f3"
  ];

  networking.useHostResolvConf = lib.mkDefault (!config.systemd.network.enable);
  networking.resolvconf.dnsSingleRequest = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;
  networking.interfaces.enp0s20f0u1c2.useDHCP = true;

  networking.wireless = {
    extraConfig = ''
      p2p_disabled=1
    '';
    enable = true;
    userControlled = {
      enable = true;
      group = "users";
    };
    networks = {
    };
  };
}
