{
  lib,
  nixpkgs,
  ...
}:
with lib; {
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1t"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "android-sdk-tools"
      "bcompare"
      "dell-command-configure"
      "discord"
      "genymotion"
      "hplip"
      "nosql-workbench"
      "slack"
      "steam"
      "steam-original"
      "steam-run"
      "vscode-extension-github-copilot"
      "vscode-extension-ms-vscode-cpptools"
      "vscode-extension-ms-vscode-remote-remote-ssh"
      "zerotierone"
    ];
}
