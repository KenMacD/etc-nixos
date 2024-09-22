{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  curl,
  openssl,
  version,
  hash,
  extraBuildInputs ? [],
  osTarget ? "ubuntu2204",
}:
stdenv.mkDerivation {
  pname = "mongodb";
  inherit version;

  src = fetchurl {
    # https://www.mongodb.com/try/download/community-edition/releases
    url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${osTarget}-${version}.tgz";
    inherit hash;
  };

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs =
    [
      stdenv.cc.cc.libgcc
      curl
      openssl
    ]
    ++ extraBuildInputs;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/mongod $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "A scalable, high-performance, open source NoSQL database";
    homepage = "http://www.mongodb.org";
    platforms = ["x86_64-linux"];
    # TODO: figure out unfree for self
    # maybe something in https://discourse.nixos.org/t/allowunfree-predicate-does-not-apply-to-self-packages/21734
    # license = licenses.unfree;
  };
}
