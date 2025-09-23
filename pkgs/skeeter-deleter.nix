{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  python,
  setuptools,
  annotated-types,
  anyio,
  atproto,
  authlib,
  certifi,
  cffi,
  charset-normalizer,
  click,
  cryptography,
  dataclasses-json,
  dateutils,
  dnspython,
  exceptiongroup,
  h11,
  httpcore,
  httpx,
  idna,
  libipld,
  markdown-it-py,
  marshmallow,
  mdurl,
  mypy-extensions,
  packaging,
  pycparser,
  pydantic,
  pydantic-core,
  pygments,
  python-dateutil,
  python-magic,
  pytz,
  requests,
  rich,
  six,
  sniffio,
  typing-inspect,
  typing-extensions,
  urllib3,
  websockets,
}: let
  version = "0.0.5-alpha";
in
  buildPythonApplication {
    pname = "skeeter-deleter";
    inherit version;
    format = "other";

    src = fetchFromGitHub {
      owner = "Gorcenski";
      repo = "skeeter-deleter";
      rev = "v${version}";
      hash = "sha256-aPKlB/66uDTrvwNASBRf4NXCu2dmlNFBbC8tFmuvdL4=";
    };

    propagatedBuildInputs = [
      annotated-types
      anyio
      atproto
      authlib
      certifi
      cffi
      charset-normalizer
      click
      cryptography
      dataclasses-json
      dateutils
      dnspython
      exceptiongroup
      h11
      httpcore
      httpx
      idna
      libipld
      markdown-it-py
      marshmallow
      mdurl
      mypy-extensions
      packaging
      pycparser
      pydantic
      pydantic-core
      pygments
      python-dateutil
      python-magic
      pytz
      requests
      rich
      six
      sniffio
      typing-inspect
      typing-extensions
      urllib3
      websockets
    ];

    postPatch = ''
      # Add shebang line since it doesn't exist in the source
      sed -i '1i#!${python.interpreter}' skeeter_deleter.py
    '';

    # Install the script and make it executable
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp skeeter_deleter.py $out/bin/skeeter-deleter
      chmod +x $out/bin/skeeter-deleter
      runHook postInstall
    '';

    #pythonImportsCheck = [ "skeeter_deleter" ];

    meta = with lib; {
      description = "A github action for auto-deleting Bluesky posts";
      homepage = "https://github.com/Gorcenski/skeeter-deleter";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  }
