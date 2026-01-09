{pkgs, ...}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    (python313.withPackages (ps:
      with ps; [
        cython
        pip
        pip-tools
        setuptools
        tox
        virtualenv
      ]))
  ];
}
