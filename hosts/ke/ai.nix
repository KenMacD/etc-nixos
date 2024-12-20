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
    ];
  };

  networking.extraHosts = ''
    0.0.0.0 telemetry.crewai.com
  '';

  # Looking at https://github.com/ollama/ollama/tree/main/llm
  # needs to update llama.cpp to a newer version that supports the
  # .#opencl version in the llama.cpp flake. Then hopefully provide
  # options to build with that. Otherwise look at the docker containers:
  #
  # ghcr.io/ggerganov/llama.cpp:light-intel-b3868
  # ghcr.io/ggerganov/llama.cpp:server-intel-b3868
  #
  # They have the binaries but not the libraries. I'd need both to link
  # with ollama
  services.ollama.enable = true;
  services.open-webui = {
    enable = true;
    port = 3001;
  };

  # TODO: try when not broken: services.private-gpt.enable = true;
  # TODO: try comfyanonymous/ComfyUI pkg?

  python3SystemPackages = with pkgs.python3Packages; [
    # vllm
    instructor
    huggingface-hub
    llm
    local.llm-claude-3
    local.llm-ollama
  ];

  environment.systemPackages = with pkgs; [
    aichat
    aider-chat
    code-cursor
    fabric-ai
    local.files-to-prompt
    lmstudio # to try, open-webui-like?
    local.magic-cli
    mods # pipe command output to a question
    openai-whisper
    pandoc # Test html -> markdown
    local.repopack # Testing
    shell-gpt # $ sgpt ...
    tgpt # $ tgpt question
    local.windsurf
    (warp-terminal.override {waylandSupport = true;}) # Testing (closed-sources though)

    # Support tools
    argc
    jq
  ];
}
