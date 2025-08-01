{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytest,
  lxml,
  six,
}:
buildPythonPackage rec {
  pname = "pynzbget";
  version = "0.6.4";

  src = fetchFromGitHub {
    owner = "caronc";
    repo = "pynzbget";
    rev = "v${version}";
    sha256 = "sha256-LFLrBiQV0MKM81zHS+OGNk2XD53DUZ6pmGUJnjQglEs=";
  };

  postPatch = ''
    sed -i '/pytest-runner/d' setup.py
  '';

  pyproject = true;

  build-system = [setuptools];

  propagatedBuildInputs = [
    lxml
    six
  ];

  meta = with lib; {
    description = "A Python Framework for NZBGet & SABnzbd Scripting";
    homepage = "https://github.com/caronc/pynzbget";
    license = licenses.gpl3;
    maintainers = [];
  };
}
