{ config, lib, pkgs, ... }: {

  # Link both with libressl instead.
  nixpkgs.overlays = [
    (self: super: {
      msmtp = (super.msmtp.override {
        gnutls = null;
      }).overrideAttrs (old: {
        buildInputs = (super.buildInputs or []) ++ [super.libressl];
        configureFlags = (super.configureFlags or []) ++ ["--with-tls=libtls"];
      });
      # Switch to a newer version from to include xoauth2 support,
      fdm = (super.fdm.override {
        openssl = super.libressl;
      }).overrideAttrs (old: {
        version = "cf19f51f5b33c5a05fe41bd4a614063a9b706693";
        src = super.fetchFromGitHub {
          owner = "nicm";
          repo = "fdm";
          rev = "cf19f51f5b33c5a05fe41bd4a614063a9b706693";
          sha256 = "0x0ich0cl0h7y6zsg7s9agj0plgw976i1a4zrqz6kpbldfg1r63q";
        };
        configureFlags = (super.configureFlags or []) ++ ["--with-tls=libtls"];
      });
    })
  ];
}
