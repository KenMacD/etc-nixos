{
  config,
  pkgs,
  ...
}: {
  imports = [
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.systemd-boot.enable = false;

  networking = {
    hostName = "atom";
    domain = "home.macdermid.ca";
    firewall = {
      allowedTCPPorts = [];
    };
    useNetworkd = true;
    interfaces.enp4s0.useDHCP = true;
    usePredictableInterfaceNames = true;
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
  ];
}
