{ stdenv, lib, fetchzip, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "focalboard";
  version = "0.12.1";

  src = fetchzip {
    url = "https://github.com/mattermost/focalboard/releases/download/v${version}/focalboard-server-linux-amd64.tar.gz";
    sha256 = "sha256-hvouCps54qApr7LXN2dou5WVRoTrSGd54nqBh5Hle7Q=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = false;
  # dontFixup = true;

  installPhase = ''
    cp -r $src $out
    substituteInPlace $out/config.json --replace ./pack $out/pack
    substituteInPlace $out/config.json --replace "''\t" "    "
    runHook postInstall
  '';

  meta = with lib; {
    description = "Focalboard is an open source, self-hosted alternative to Trello, Notion, and Asana.";
    homepage = "https://github.com/mattermost/focalboard";
    platforms = platforms.all;
  };
}
