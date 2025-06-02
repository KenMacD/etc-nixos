{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  postgresql,
}:
# Modified from: https://github.com/diogotcorreia/dotfiles/blob/nixos/packages/pgvecto-rs.nix
# Build from source is in git history, but takes multiple gigs of space and is slow.
# Hash: nix store prefetch-file "https://github.com/tensorchord/pgvecto.rs/releases/download/v0.4.0/vectors-pg16_0.4.0_amd64.deb"
let
  versionHashes = {
    "16" = "sha256-uqjG9Cr2OeDL1SAW75CXkoR9Jh/9UUWqiSi2rYhEgy4=";
    "17" = lib.fakeHash; # Does not exist
  };
  major = lib.versions.major postgresql.version;
in
  stdenv.mkDerivation rec {
    pname = "pgvecto-rs";
    version = "0.4.0";

    nativeBuildInputs = [dpkg];

    src = fetchurl {
      url = "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}_${version}_amd64.deb";
      hash = versionHashes."${major}";
    };

    unpackCmd = "dpkg -x $src source";

    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      install -D -t $out/lib usr/lib/postgresql/${major}/lib/*.so
      install -D -t $out/share/postgresql/extension usr/share/postgresql/${major}/extension/*.sql
      install -D -t $out/share/postgresql/extension usr/share/postgresql/${major}/extension/*.control
    '';

    meta = with lib; {
      description = "Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
      homepage = "https://github.com/tensorchord/pgvecto.rs";
      license = licenses.asl20;
      maintainers = with maintainers; [];
    };
  }
