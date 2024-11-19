{
  # Include modules that have no side-effects by default
  imports = [
    ./home-wifi.nix # Specific trusted-network config

    ./plandex.nix

    ./python-packages.nix

    ./sccache.nix

    ./sftp-users.nix # add an 'sftpOnly' option on users

    ./sway-desktop.nix # My sway desktop configuration

    ./zerotier.nix
  ];
}
