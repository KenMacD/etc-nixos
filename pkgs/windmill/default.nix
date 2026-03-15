{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  glibc,
  libxml2_13,
  xmlsec,
  openssl,
  cyrus_sasl,
  krb5,
}: let
  version = "1.657.1";
in
  stdenvNoCC.mkDerivation rec {
    pname = "windmill-ee";
    inherit version;

    src = fetchurl {
      url = "https://github.com/windmill-labs/windmill/releases/download/v${version}/windmill-ee-amd64";
      hash = "sha256-XvppfUtExg4n31Lng282PhBw5b4slmiknb4gydQ7GZA=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    postFixup = ''
      # Create symlink for libsasl2.so.2 -> libsasl2.so.3
      # The binary expects libsasl2.so.2 but cyrus_sasl provides libsasl2.so.3
      mkdir -p $out/lib
      ln -s ${cyrus_sasl}/lib/libsasl2.so.3 $out/lib/libsasl2.so.2

      # Add our lib directory to RPATH
      patchelf --add-rpath $out/lib $out/bin/windmill
    '';

    propagatedBuildInputs = [
      glibc
      libxml2_13
      xmlsec
      openssl
      cyrus_sasl
      krb5
    ];

    # Skip unpacking since this is a binary
    unpackPhase = "true";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 -D $src $out/bin/windmill
      runHook postInstall
    '';

    meta = with lib; {
      changelog = "https://github.com/windmill-labs/windmill/blob/${src.rev}/CHANGELOG.md";
      description = "Open-source developer platform to power your entire infra and turn scripts into webhooks, workflows and UIs";
      homepage = "https://windmill.dev";
      license = lib.licenses.agpl3Only;
      mainProgram = "windmill";
      platforms = ["x86_64-linux"];
    };
  }
