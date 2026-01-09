{pkgs, ...}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    nodejs
    pnpm
    yarn
  ];
}
