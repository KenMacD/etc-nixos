{ lib
, stdenv
, fetchurl
, coreutils
, autoPatchelfHook
, python38
, which
}:

stdenv.mkDerivation rec {
  pname = "zephyr-toolchain";
  version = "0.13.2";
  arch = "arm";
  targetArch = stdenv.targetPlatform.linuxArch;

  src = fetchurl {
    url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-toolchain-${arch}-${version}-linux-${targetArch}-setup.run";
    hash = "sha256-D4CI4hgipnJwy9OPxurGA9PH0b7g0XhsygPrvlXOzFo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    python38
    which
  ];

  unpackPhase = "sh $src --noexec --target .";
  installPhase = "sh setup.sh -d $out -norc -nocmake -y";

  meta = with lib; {
    description = "Zephyr embedded RTOS toolchain";
    homepage = "https://www.zephyrproject.org/";
    license = licenses.asl20;
    platforms = platforms.x86_64;
  };
}
