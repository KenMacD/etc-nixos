{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  glibc,
  libxml2_13,
  xmlsec,
  openssl,
}: let
  version = "1.581.1";
in
  stdenvNoCC.mkDerivation rec {
    pname = "windmill-ee";
    inherit version;

    src = fetchurl {
      url = "https://github.com/windmill-labs/windmill/releases/download/v${version}/windmill-ee-amd64";
      hash = "sha256-9shsi0mGydIfMl5lMPz8nKbVsUM48WBaK4H+6IOB+hE=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    propagatedBuildInputs = [
      glibc
      libxml2_13
      xmlsec
      openssl
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
