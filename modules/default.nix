{
  # Include modules that do not change anything unless enabled
  imports = [
    ./content-addressed.nix # Test enable content addresses setup

    ./home-wifi.nix # Specific trusted-network config

    ./sway-desktop.nix # My sway desktop configuration

    ./zerotier.nix
  ];
}
