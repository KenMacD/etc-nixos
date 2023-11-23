{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
# To make copilot work in vscodium follow:
# https://github.com/VSCodium/vscodium/discussions/1487
#
# curl https://github.com/login/device/code -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email'
# https://github.com/login/device/
# curl https://github.com/login/oauth/access_token -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email&device_code=YOUR_DEVICE_ID&grant_type=urn:ietf:params:oauth:grant-type:device_code'
# use access_token
let
  vscode-extensions = inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace;
in {
  # secret service needed to store API key
  services.passSecretService.enable = true;
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = pkgs.vscodium;
      vscodeExtensions = with vscode-extensions; [
        adamhartford.vscode-base64
        alefragnani.project-manager
        arrterian.nix-env-selector
        asciidoctor.asciidoctor-vscode
        asvetliakov.vscode-neovim
        bmalehorn.vscode-fish
        brettm12345.nixfmt-vscode
        crystal-lang-tools.crystal-lang
        dbaeumer.vscode-eslint
        eamodio.gitlens
        emmanuelbeziat.vscode-great-icons
        esbenp.prettier-vscode
        foam.foam-vscode
        formulahendry.code-runner
        github.copilot
        github.copilot-chat
        golang.go
        hashicorp.terraform
        jnoortheen.nix-ide
        llvm-vs-code-extensions.vscode-clangd
        marus25.cortex-debug
        mcu-debug.debug-tracker-vscode
        mcu-debug.memory-view
        mcu-debug.rtos-views
        mcu-debug.peripheral-viewer
        mikestead.dotenv
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.python
        ms-toolsai.jupyter
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        nordic-semiconductor.nrf-connect
        nordic-semiconductor.nrf-terminal
        nordic-semiconductor.nrf-devicetree
        nordic-semiconductor.nrf-kconfig
        pomdtr.excalidraw-editor
        probe-rs.probe-rs-debugger
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        serayuzgur.crates
        shardulm94.trailing-spaces
        shd101wyy.markdown-preview-enhanced
        tamasfe.even-better-toml
        tintinweb.graphviz-interactive-preview
        twxs.cmake
        yzhang.markdown-all-in-one
      ];
    })
  ];
}
