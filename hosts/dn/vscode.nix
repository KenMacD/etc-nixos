{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override
      {
        vscode = pkgs.vscodium;
        vscodeExtensions = with pkgs.vscode-extensions; [
          alefragnani.project-manager
          arrterian.nix-env-selector
          asciidoctor.asciidoctor-vscode
          brettm12345.nixfmt-vscode
          dbaeumer.vscode-eslint
          eamodio.gitlens
          emmanuelbeziat.vscode-great-icons
          esbenp.prettier-vscode
          file-icons.file-icons
          foam.foam-vscode
          formulahendry.code-runner
          golang.go
          llvm-vs-code-extensions.vscode-clangd
          mikestead.dotenv
          ms-azuretools.vscode-docker
          ms-python.python
          ms-toolsai.jupyter
          ms-vscode-remote.remote-ssh
          ms-vscode.cpptools
          rust-lang.rust-analyzer
          serayuzgur.crates
          shardulm94.trailing-spaces
          shd101wyy.markdown-preview-enhanced
          yzhang.markdown-all-in-one
        ];
      })
  ];
}
