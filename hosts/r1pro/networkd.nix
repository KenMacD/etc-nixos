{
  config,
  pkgs,
  lib,
  ...
}: {

  environment.systemPackages = with pkgs; [
    iw
    wavemon
    wirelesstools
    wpa_supplicant
    wpa_supplicant_gui
  ];

  systemd.network.enable = true;

  networking.usePredictableInterfaceNames = true;
  networking.wireless.interfaces = [
    "wlp4s0"
  ];

  networking.useHostResolvConf = lib.mkDefault (!config.systemd.network.enable);
  networking.resolvconf.dnsSingleRequest = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.enp3s0.useDHCP = true;

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
      MacDermid = {
        psk = "curlyhairbaabaabaa";
      };
    };
  };
}
