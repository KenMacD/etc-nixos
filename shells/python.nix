{pkgs, ...}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    (python3.withPackages (ps:
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
