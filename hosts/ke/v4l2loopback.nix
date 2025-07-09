{
  config,
  pkgs,
  ...
}: {
  # Load module by default
  boot.kernelModules = [
    "v4l2loopback"
  ];

  # Create /dev/video20 with xor of capture/output (only 'output' after 'capture')
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=20 exclusive_caps=1 card_label="Loopback"
  '';

  # Adds module
  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

  environment.systemPackages = [
    pkgs.v4l-utils
  ];
}
