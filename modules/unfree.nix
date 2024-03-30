{
  lib,
  nixpkgs,
  ...
}:
with lib; {

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "android-sdk-tools"
      "bcompare"
      "dell-command-configure"
      "discord"
      "genymotion"
      "hplip"
      "j-link"
      "megasync"
      "mongodb-4"
      "nosql-workbench"
      "obsidian"
      "slack"
      "steam"
      "steam-original"
      "steam-run"
      "unifi-controller"
      "unrar"
      "vscode-extension-github-copilot"
      "vscode-extension-ms-vscode-cpptools"
      "vscode-extension-ms-vscode-remote-remote-ssh"
      "unifi-controller"
      "unrar"
      "vscode"
      "zerotierone"
    ];
}
