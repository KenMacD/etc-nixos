{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs;
    [
      (vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = with pkgs.vscode-extensions;
          [
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
              # Needed for cortex-debug
              name = "debug-tracker-vscode";
              publisher = "mcu-debug";
              version = "0.0.15";
              sha256 = "sha256-2u4Moixrf94vDLBQzz57dToLbqzz7OenQL6G9BMCn3I=";
            }
            {
              # Needed for cortex-debug
              name = "memory-view";
              publisher = "mcu-debug";
              version = "0.0.20";
              sha256 = "sha256-tPlYF6qqJTVOKjBkBzdaQduRSXmN1bbMtwgvn+RI+K0=";
            }
            {
              # Needed for cortex-debug
              name = "rtos-views";
              publisher = "mcu-debug";
              version = "0.0.6";
              sha256 = "sha256-23ANnrPpFzIIRoUekkonzTzJAQhkiXqUVXil6wacJdI=";
            }
            {
              # Needed for cortex-debug
              name = "peripheral-viewer";
              publisher = "mcu-debug";
              version = "1.4.5";
              sha256 = "sha256-6k83lmHLetadg1nAE2Iwwt2paO81gBmvn1R5GaDjR/I=";
            }
            {
              name = "cortex-debug";
              publisher = "marus25";
              version = "1.11.1";
              sha256 = "sha256-zcBHr0cKWAbgQarDb3OCFohRuCPhHbazzFgqvNE4lP0=";
            }
                   {
              name = "probe-rs-debugger";
              publisher = "probe-rs";
              version = "0.17.4";
              sha256 = "sha256-GRZgXFyzVOtb4KikJqu5QNxJe51TkN0Qa7lU9Tgt4sM=";
            }
            {
              name = "remote-containers";
              publisher = "ms-vscode-remote";
              version = "0.289.0";
              sha256 = "sha256-U7gilVJx8c+nmh6YVGVLoRKjC2n71Vih6aALWkcQw0I=";
            }
            {
              name = "nrf-connect";
              publisher = "nordic-semiconductor";
              version = "2023.2.56";
              sha256 = "sha256-RdgB8+wnxLUwkwEU5VmCIJIKqr44bEWLk9/KGRQCmQw=";
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
              version = "2023.4.1";
              sha256 = "sha256-LnqT25uZ6M/CZVYdjF31Fd+4VtcgLkVCRLCH4+idrqI=";
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
