{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}: {
  # secret service needed to store API key
  services.passSecretService.enable = true;
  services.gnome.gnome-keyring.enable = true;

  #  xdg.mime = {
  #    enable = true;
  #    defaultApplications = {
  #      "x-scheme-handler/vscodium" = "codium-url-handler.desktop";
  #    };
  #  };

  environment.systemPackages = with pkgs; [
    nil # Nix language server

    (vscode-with-extensions.override {
      inherit vscode;
      vscodeExtensions = lib.concatLists [
        # NixOS available extensions
        (with pkgs.vscode-extensions; [
          github.copilot
          github.copilot-chat
          continue.continue
        ])
        # Nix Community extensions
        (with inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace; [
          inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace."42crunch".vscode-openapi

          aaron-bond.better-comments
          adamhartford.vscode-base64
          alefragnani.project-manager
          amazonwebservices.aws-toolkit-vscode
          arrterian.nix-env-selector
          asciidoctor.asciidoctor-vscode
          asvetliakov.vscode-neovim
          augustocdias.tasks-shell-input
          bierner.markdown-mermaid
          bmalehorn.vscode-fish
          bruno-api-client.bruno
          charliermarsh.ruff
          christian-kohler.path-intellisense
          codeium.codeium
          crystal-lang-tools.crystal-lang
          # Closed source now? Trying continue.continue instead danielsanmedium.dscodegpt
          dbaeumer.vscode-eslint
          deerawan.vscode-dash # Lookup upstream docs
          eamodio.gitlens
          editorconfig.editorconfig
          emmanuelbeziat.vscode-great-icons
          esbenp.prettier-vscode
          fill-labs.dependi
          foam.foam-vscode
          formulahendry.code-runner
          foxundermoon.shell-format
          github.vscode-pull-request-github
          gitpod.gitpod-desktop
          golang.go
          # Broken: 2024-04-29       hashicorp.terraform
          hbenl.vscode-mocha-test-adapter
          hbenl.vscode-test-explorer
          jebbs.plantuml
          jnoortheen.nix-ide
          kamadorueda.alejandra
          llvm-vs-code-extensions.vscode-clangd
          maelvalais.autoconf
          marus25.cortex-debug
          mattflower.aider
          mcu-debug.debug-tracker-vscode
          mcu-debug.memory-view
          mcu-debug.peripheral-viewer
          mcu-debug.rtos-views
          mikestead.dotenv
          mkhl.direnv
          ms-azuretools.vscode-docker
          ms-kubernetes-tools.vscode-kubernetes-tools
          # Try ruff ms-python.black-formatter
          # Try ruff ms-python.flake8
          ms-python.pylint
          ms-python.python
          ms-python.vscode-pylance
          ms-toolsai.jupyter
          # broken 2024-03-27 ms-vscode.cmake-tools
          ms-vscode.test-adapter-converter
          vscode-extensions.ms-vscode.cpptools
          (ms-vscode.vscode-embedded-tools.overrideAttrs (_: {
            sourceRoot = "extension";
          }))
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          msedge-dev.gnls
          nhoizey.gremlins
          nordic-semiconductor.nrf-connect
          nordic-semiconductor.nrf-devicetree
          nordic-semiconductor.nrf-kconfig
          nordic-semiconductor.nrf-terminal
          pomdtr.excalidraw-editor
          platformio.platformio-ide
          probe-rs.probe-rs-debugger
          redhat.vscode-yaml
          rust-lang.rust-analyzer
          shardulm94.trailing-spaces
          shd101wyy.markdown-preview-enhanced
          streetsidesoftware.code-spell-checker
          streetsidesoftware.code-spell-checker-canadian-english
          supermaven.supermaven # Try code complete?
          tamasfe.even-better-toml
          threadheap.serverless-ide-vscode
          tintinweb.graphviz-interactive-preview
          twxs.cmake
          usernamehw.errorlens
          vadimcn.vscode-lldb
          xaver.clang-format
          yuichinukiyama.vscode-preview-server
          yzhang.markdown-all-in-one
        ])
      ];
    })
  ];
}
