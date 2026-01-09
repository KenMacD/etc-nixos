{pkgs, ...}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    rustup
    llvmPackages.bintools
    llvmPackages.clang
    llvmPackages.lld
    pkg-config
    sccache

    # Very commonly needed by crates
    openssl
  ];
  shellHook = ''
    export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
  '';
}
