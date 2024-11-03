{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  setuptools,
  poetry-core,
  grpcio-tools,
}: let
  pname = "forwardlib";
  version = "bdc012c";
in
  buildPythonApplication {
    inherit pname version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "Veids";
      repo = pname;
      rev = version;
      hash = "sha256-xH5tDRVqViGG842m2vOPHduZg9mn4WfBVg3AeXcjKS4=";
    };

    build-system = [setuptools poetry-core];

    propagatedBuildInputs = [grpcio-tools];

    meta = with lib; {
      homepage = "https://github.com/Veids/forwardlib";
    };
  }
