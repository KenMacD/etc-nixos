{fetchFromGitHub}:
rec {
  version = "1.68.0";
  src = fetchFromGitHub {
    owner = "immich-app";
    repo = "immich";
    rev = "v${version}";
    sha256 = "sha256-Z7kvDLIPlPSYdZ+YPn/o1jo981N5/4ybO6DIQLiwhC0=";
  };
}
