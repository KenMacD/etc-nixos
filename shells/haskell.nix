{pkgs, ...}:
pkgs.mkShell {
  # https://haskell4ninx.readthedocs.io/nixpkgs-users-guide.html#how-to-create-a-development-environment
  packages = with pkgs; [
    haskellPackages.ghc
    haskellPackages.cabal-install
    haskellPackages.haskell-language-server
  ];
}
