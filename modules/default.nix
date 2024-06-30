{
  # Include modules that have no side-effects by default
  imports = [
    ./home-wifi.nix # Specific trusted-network config

    ./sftp-users.nix # add an 'sftpOnly' option on users

    ./sway-desktop.nix # My sway desktop configuration

    ./zerotier.nix
  ];
}
