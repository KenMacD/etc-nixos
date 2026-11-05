{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  uv-build,
  click,
  tiktoken,
}: let
  version = "1.0";
in
  buildPythonApplication {
    pname = "llm-ttok";
    inherit version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "simonw";
      repo = "ttok";
      rev = version;
      hash = "sha256-VnslA5tYcrKLZJOXJi3ze/zhPyghBUlbuf6xpCDezgM=";
    };

    # 1.0 switched from setuptools to the uv_build backend; relax its version
    # pin so nixpkgs' uv-build satisfies it (same pattern as mcp2cli).
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail "uv_build>=0.11.0,<0.12.0" "uv_build"
    '';

    build-system = [uv-build];

    propagatedBuildInputs = [
      click
      tiktoken
    ];

    pythonImportsCheck = ["ttok"];

    meta = with lib; {
      description = "Count and truncate text based on tokens";
      homepage = "https://github.com/simonw/ttok";
      license = licenses.asl20;
      maintainers = [];
    };
  }
