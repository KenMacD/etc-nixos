{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}: let
  vscode-extensions = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = config.nixpkgs.config.allowUnfreePredicate;
    overlays = [inputs.nix-vscode-extensions.overlays.default];
  };
in {
  # secret service needed to store API key
  services.passSecretService.enable = true;
  services.gnome.gnome-keyring.enable = true;

  #  xdg.mime = {
  #    enable = true;
  #    defaultApplications = {
  #      "x-scheme-handler/vscodium" = "codium-url-handler.desktop";
  #    };
  #  };

  environment.systemPackages = let
    baseExtensions = lib.concatLists [
      (with pkgs.vscode-extensions; [
        github.copilot
        github.copilot-chat
        ms-vscode-remote.remote-containers
      ])
      (with (vscode-extensions.forVSCodeVersion pkgs.vscode.version).vscode-marketplace; [
        aaron-bond.better-comments
        streetsidesoftware.code-spell-checker
        streetsidesoftware.code-spell-checker-canadian-english
        deerawan.vscode-dash # Lookup upstream docs
        mkhl.direnv
        editorconfig.editorconfig
        usernamehw.errorlens
        nhoizey.gremlins
        christian-kohler.path-intellisense
        alefragnani.project-manager
        ms-vscode-remote.remote-ssh
        augustocdias.tasks-shell-input
        ms-vscode.test-adapter-converter
        hbenl.vscode-mocha-test-adapter
        shardulm94.trailing-spaces
        emmanuelbeziat.vscode-great-icons
        pascalreitermann93.vscode-yaml-sort
      ])
    ];
    # TODO: move to devshells?
    vscode-ether = pkgs.vscode-with-extensions.override {
      inherit (pkgs) vscode;
      vscodeExtensions =
        baseExtensions
        ++ (with (vscode-extensions.forVSCodeVersion pkgs.vscode.version).vscode-marketplace; [
          cyfrin.aderyn
          nomicfoundation.hardhat-solidity
          tintinweb.graphviz-interactive-preview
          tintinweb.solidity-visual-auditor
          tintinweb.vscode-ethover
          tintinweb.vscode-inline-bookmarks
          tintinweb.vscode-solidity-language
          tintinweb.vscode-solidity-flattener
        ]);
    };
  in
    with pkgs; [
      nil # Nix language server

      (pkgs.writeShellScriptBin "code-ether" ''
        ${vscode-ether}/bin/code "$@"
      '')

      (vscode-with-extensions.override {
        inherit vscode;
        vscodeExtensions = lib.concatLists [
          # NixOS available extensions
          (with pkgs.vscode-extensions; [
            github.copilot
            github.copilot-chat
            continue.continue

            ms-vscode-remote.remote-containers
            ms-vscode.cpptools
          ])
          # Nix Community extensions
          #(with inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace; [
          (with (vscode-extensions.forVSCodeVersion vscode.version).vscode-marketplace; [
            inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace."42crunch".vscode-openapi

            aaron-bond.better-comments
            adamhartford.vscode-base64
            alefragnani.project-manager
            amazonwebservices.aws-toolkit-vscode
            apertia.vscode-aider
            arrterian.nix-env-selector
            # TODO: broken 2025-03-03 asciidoctor.asciidoctor-vscode
            asvetliakov.vscode-neovim
            augustocdias.tasks-shell-input
            bierner.markdown-mermaid
            blaxk.serverless-command # Testing with serverless framework
            bmalehorn.vscode-fish
            bruno-api-client.bruno
            charliermarsh.ruff
            christian-kohler.path-intellisense
            codeium.codeium
            crystal-lang-tools.crystal-lang
            # Closed source now? Trying continue.continue instead danielsanmedium.dscodegpt
            davidanson.vscode-markdownlint
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
            github.vscode-github-actions
            github.vscode-pull-request-github
            gitpod.gitpod-desktop
            golang.go
            # Broken: 2024-04-29       hashicorp.terraform
            hbenl.vscode-mocha-test-adapter
            hbenl.vscode-test-explorer
            humao.rest-client
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
            # ms-python.vscode-pylance
            ms-toolsai.jupyter
            ms-vscode.cmake-tools
            ms-vscode.test-adapter-converter
            (ms-vscode.vscode-embedded-tools.overrideAttrs (_: {
              sourceRoot = "extension";
            }))
            ms-vscode-remote.remote-ssh
            msedge-dev.gnls
            nhoizey.gremlins
            nicolasvuillamy.vscode-groovy-lint
            pascalreitermann93.vscode-yaml-sort
            pomdtr.excalidraw-editor
            # platformio.platformio-ide
            probe-rs.probe-rs-debugger
            redhat.vscode-yaml
            rust-lang.rust-analyzer
            saoudrizwan.claude-dev
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

            # Nordic Extensions: https://marketplace.visualstudio.com/items?itemName=nordic-semiconductor.nrf-connect-extension-pack
            ms-vscode.cmake-tools
            nordic-semiconductor.nrf-connect
            nordic-semiconductor.nrf-devicetree
            nordic-semiconductor.nrf-kconfig
            nordic-semiconductor.nrf-terminal
            trond-snekvik.gnu-mapfiles
            twxs.cmake

            # AI Extensions
            saoudrizwan.claude-dev
          ])
        ];
      })
    ];
}
