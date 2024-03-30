{
  pkgs,
  lib,
  ...
}: let
  pname = "insomnium";
  version = "0.2.3-a";
  name = "${pname}-${version}";

  src = pkgs.fetchurl {
    url = "https://github.com/ArchGPT/insomnium/releases/download/core%40${version}/Insomnium.Core-${version}.AppImage";
    sha256 = "sha256-hFpAFxyoBtQPH+NPeQz9wjJSpyPm6yLfjXOQSomnoXE=";
  };
in
  pkgs.appimageTools.wrapType1 rec {
    # ISO 9660 file that are also ELF executables.
    inherit name src;

    extraInstallCommands = ''
      mv $out/bin/${name} $out/bin/${pname}
    '';

    meta = with lib; {
      description = "Fast local API testing tool that is privacy-focused and 100% local";
      homepage = "https://github.com/ArchGPT/insomnium";
      license = licenses.mit;
      maintainers = [];
    };
  }
