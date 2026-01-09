{pkgs, ...}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    alejandra
    cargo
    cargo-binutils
    cargo-expand
    cargo-flamegraph
    cargo-generate
    clippy
    llvmPackages.bintools
    llvmPackages.clang
    llvmPackages.lld
    pkg-config
    rustc
    rustup
    rust-analyzer
    sccache

    # Very commonly needed by crates
    openssl
  ];
  shellHook = ''
    export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
  '';
}
