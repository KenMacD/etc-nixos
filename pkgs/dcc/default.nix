{ stdenv, lib, fetchurl, dpkg, autoPatchelfHook, libsmbios, openssl }:

# Used https://github.com/NixOS/nixpkgs/pull/84926 as a template
# then converted to use autoPatchelfHook instead, and link with
# the dependencies from other pkgs.

stdenv.mkDerivation rec {
  pname = "dell-command-configure";
  version = "4.6.0-277";

  src = fetchurl {
    url =
      "https://dl.dell.com/FOLDER07737981M/1/command-configure_4.6.0-277.ubuntu20_amd64.tar.gz";
    # The CDN blocks the Curl user-agent, so set to blank instead.
    curlOpts = ''-A=""'';
    sha256 = "d4e6e6cdfb34dac699e7521d4149e34647a9bc56d93eecf7ba3dffef4665c457";
  };

  buildInputs = [ libsmbios openssl stdenv.cc.cc.lib ];
  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  sourceRoot = pname;
  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    mkdir ${pname}
    tar -C ${pname} -xzf ${src}
    dpkg-deb -x ${pname}/command-configure_${version}.ubuntu20_amd64.deb ${pname}/command-configure
    dpkg-deb -x ${pname}/srvadmin-hapi_9.5.0_amd64.deb ${pname}/srvadmin-hapi
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib

    install -t $out/lib -m644 -v command-configure/opt/dell/dcc/libhapiintf.so
    install -t $out/bin -m755 -v command-configure/opt/dell/dcc/cctk
    install -t $out/bin -m755 -v srvadmin-hapi/opt/dell/srvadmin/sbin/dchcfg

    for lib in $(find srvadmin-hapi/opt/dell/srvadmin/lib64 -type l); do
        install -t $out/lib -m644 -v $lib
    done
  '';

  meta = with lib; {
    description = "Configure BIOS settings on Dell laptops.";
    homepage =
      "https://www.dell.com/support/article/us/en/19/sln311302/dell-command-configure";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
