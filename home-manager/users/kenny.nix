{
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      hello
    ];

    username = "kenny";
    homeDirectory = "/home/kenny";

    stateVersion = "25.05";
  };
}
