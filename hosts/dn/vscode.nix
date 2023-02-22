{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs;
    [
      (vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = with pkgs.vscode-extensions;
          [
            _4ops.terraform
            alefragnani.project-manager
            arrterian.nix-env-selector
            asciidoctor.asciidoctor-vscode
            asvetliakov.vscode-neovim
            bmalehorn.vscode-fish
            brettm12345.nixfmt-vscode
            dbaeumer.vscode-eslint
            eamodio.gitlens
            emmanuelbeziat.vscode-great-icons
            esbenp.prettier-vscode
            file-icons.file-icons
            foam.foam-vscode
            formulahendry.code-runner
            golang.go
            hashicorp.terraform
            llvm-vs-code-extensions.vscode-clangd
            mikestead.dotenv
            ms-azuretools.vscode-docker
            ms-kubernetes-tools.vscode-kubernetes-tools
            ms-python.python
            ms-toolsai.jupyter
            ms-vscode-remote.remote-ssh
            ms-vscode.cmake-tools
            ms-vscode.cpptools
            redhat.vscode-yaml
            rust-lang.rust-analyzer
            serayuzgur.crates
            shardulm94.trailing-spaces
            shd101wyy.markdown-preview-enhanced
            twxs.cmake
            yzhang.markdown-all-in-one
          ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "remote-containers";
              publisher = "ms-vscode-remote";
              version = "0.278.0";
              sha256 = "sha256-FRh3h8Jscnz1/nP+GkhaR9+r6B+5NvCKvoAvjcJvYRU=";
            }
            {
              name = "nrf-connect";
              publisher = "nordic-semiconductor";
              version = "2023.1.44";
              sha256 = "sha256-j0jjJD6cAgkPs+dIgApYCvJ9eIiVrbblyEX63wBv4wM=";
            }
            {
              name = "nrf-terminal";
              publisher = "nordic-semiconductor";
              version = "2022.11.29";
              sha256 = "sha256-NHWVl0U/KqfpJ3WK65ekLFxxotlIhY2cZIQFw0k1AU0=";
            }
            {
              name = "nrf-devicetree";
              publisher = "nordic-semiconductor";
              version = "2022.11.153";
              sha256 = "sha256-gE7SAIKOXzgbqVLcJGTgbQhriz3I74s6vPKh5DrPIyQ=";
            }
            {
              name = "nrf-kconfig";
              publisher = "nordic-semiconductor";
              version = "2022.11.50";
              sha256 = "sha256-76gtJYi8MV7MIu6MVPlmvrd7hOelQ+PDALZIec/hoLk=";
            }

          ];
      })
    ];
}
