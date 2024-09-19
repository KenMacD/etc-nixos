{
  self,
  config,
  lib,
  pkgs,
  inputs,
  system,
  options,
  ...
}: let
  local = self.packages.${system};
in {
  programs.neovim.configure.packages.myPlugins = with pkgs.vimPlugins; {
    opt = [
      copilot-vim
    ];
  };

  services.ollama.enable = true;
  services.open-webui = {
    enable = true;
    port = 3001;
  };

  # TODO: try when not broken: services.private-gpt.enable = true;
  # TODO: try comfyanonymous/ComfyUI pkg?

  python3SystemPackages = with pkgs.python3Packages; [
    # vllm
    llm
    local.llm-ollama
  ];

  environment.systemPackages = with pkgs; [
    aichat
    local.aider-chat
    gh-copilot
    fabric-ai
    fishPlugins.github-copilot-cli-fish
    (local-ai.override {with_clblas = true;})
    lmstudio # to try, open-webui-like?
    local.magic-cli
    mods # pipe command output to a question
    pandoc # Test html -> markdown
    shell-gpt # $ sgpt ...
    tgpt # $ tgpt question
  ];
}
