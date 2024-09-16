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

  services.sccache.enable = true;

  # Testing: https://github.com/intel-analytics/ipex-llm/blob/main/docs/mddocs/Quickstart/ollama_quickstart.md
  # mby try: https://github.com/intel-analytics/ipex-llm/blob/main/docs/mddocs/DockerGuides/docker_cpp_xpu_quickstart.md
  services.ollama = {
    enable = true;
    environmentVariables = {
      OLLAMA_NUM_GPU = "999";
      ZES_ENABLE_SYSMAN = "1";
      OLLAMA_INTEL_GPU = "1";
      OLLAMA_DEBUG = "1";
      OLLAMA_FORCE_ENABLE_INTEL_IGPU = "1";
      SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS = "1";
      SYCL_CACHE_PERSISTENT = "1";
    };
  };
  systemd.services.ollama = {
    environment = {
      LD_LIBRARY_PATH = "${pkgs.intel-compute-runtime.drivers}/lib:${pkgs.intel-gmmlib}/lib";
    };
  };

  services.open-webui = {
    enable = true;
    port = 3001;
  };

  # TODO: tensorflow-2.13.0 not supported for interpreter python3.12
  # services.private-gpt = {
  #   enable = true;
  # };

  # TODO: add comfyanonymous/ComfyUI pkg?

  python3SystemPackages = with pkgs.python3Packages; [
    # vllm
    llm
    local.llm-ollama
  ];

  environment.systemPackages = with pkgs; [
    aichat
    local.aider-chat
    gh-copilot
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
