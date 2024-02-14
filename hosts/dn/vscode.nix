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
  vscode = pkgs.vscode;
in {
  # secret service needed to store API key
  services.passSecretService.enable = true;
  services.gnome.gnome-keyring.enable = true;

  xdg.mime = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/vscodium" = "codium-url-handler.desktop";
    };
  };

  environment.systemPackages = with pkgs; [
    # Nix LSP for nix-ide (try nil or nixd?)
    rnix-lsp
    (vscode-with-extensions.override {
      inherit vscode;
      vscodeExtensions = with inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace; [
        aaron-bond.better-comments
        adamhartford.vscode-base64
        alefragnani.project-manager
        arrterian.nix-env-selector
        asciidoctor.asciidoctor-vscode
        asvetliakov.vscode-neovim
        augustocdias.tasks-shell-input
        bmalehorn.vscode-fish
        brettm12345.nixfmt-vscode
        christian-kohler.path-intellisense
        crystal-lang-tools.crystal-lang
        dbaeumer.vscode-eslint
        eamodio.gitlens
        editorconfig.editorconfig
        emmanuelbeziat.vscode-great-icons
        esbenp.prettier-vscode
        foam.foam-vscode
        formulahendry.code-runner
        foxundermoon.shell-format
        github.copilot
        github.copilot-chat
        github.vscode-pull-request-github
        gitpod.gitpod-desktop
        golang.go
        hashicorp.terraform
        jebbs.plantuml
        jnoortheen.nix-ide
        llvm-vs-code-extensions.vscode-clangd
        maelvalais.autoconf
        marus25.cortex-debug
        mcu-debug.debug-tracker-vscode
        mcu-debug.memory-view
        mcu-debug.peripheral-viewer
        mcu-debug.rtos-views
        mikestead.dotenv
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.python
        ms-toolsai.jupyter
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        (ms-vscode.vscode-embedded-tools.overrideAttrs (_: {
          sourceRoot = "extension";
        }))
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        msedge-dev.gnls
        nordic-semiconductor.nrf-connect
        nordic-semiconductor.nrf-devicetree
        nordic-semiconductor.nrf-kconfig
        nordic-semiconductor.nrf-terminal
        pomdtr.excalidraw-editor
        probe-rs.probe-rs-debugger
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        serayuzgur.crates
        shardulm94.trailing-spaces
        shd101wyy.markdown-preview-enhanced
        streetsidesoftware.code-spell-checker
        streetsidesoftware.code-spell-checker-canadian-english
        tamasfe.even-better-toml
        tintinweb.graphviz-interactive-preview
        twxs.cmake
        vadimcn.vscode-lldb
        xaver.clang-format
        yuichinukiyama.vscode-preview-server
        yzhang.markdown-all-in-one
      ];
    })
  ];
}
