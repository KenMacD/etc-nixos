{
  # Include modules that have no side-effects by default
  imports = [
    ./home-wifi.nix # Specific trusted-network config

    ./laptop.nix # Opt-in laptop power/battery defaults (upower, PPD, bolt, fwupd)

    ./microvm-config.nix # MicroVM configuration

    ./nordvpn-namespaced.nix

    ./python-packages.nix

    ./sccache.nix

    ./sftp-users.nix # add an 'sftpOnly' option on users

    ./sway-desktop.nix # My sway desktop configuration

    ./voxinput.nix # Voice to text service

    ./zerotier.nix
  ];
}
