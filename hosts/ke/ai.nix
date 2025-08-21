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
  #
  # When running models look at `/show info` to find the `context length` then:
  # >>> /set parameter num_ctx ___
  #
  services.ollama = {
    # Set host to 0.0.0.0 so it can be accessed by openhands in podman
    host = "0.0.0.0";
    enable = true;
    environmentVariables = {
      OLLAMA_INTEL_GPU = "1";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NEW_ENGINE = "1";
    };
  };

  # TODO: try when not broken: services.private-gpt.enable = true;
  # TODO: try comfyanonymous/ComfyUI pkg?

  # Openhands
  # ❯ podman build -f ./containers/app/Dockerfile -t openhands .
  # ❯ WORKSPACE_BASE=/tmp/workspace podman run --rm -it -p 16845:3000 \
  #           --network slirp4netns:allow_host_loopback=true \
  #           -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.27-nikolaik \
  #           -e WORKSPACE_MOUNT_PATH=$WORKSPACE_BASE \
  #           -e LOG_ALL_EVENTS=true \
  #           -e DEBUG=true \
  #           -e LLM_OLLAMA_BASE_URL="http://host.docker.internal:11434" \
  #           -e OLLAMA_API_BASE="http://host.docker.internal:11434" \
  #           -v $WORKSPACE_BASE:/opt/workspace_base:z \
  #           -v $XDG_RUNTIME_DIR/podman/podman.sock:/var/run/docker.sock:Z \
  #           --name openhands \
  #           localhost/openhands:latest
  python3SystemPackages = with pkgs.python3Packages; [
    # vllm
    instructor
    huggingface-hub
    markitdown
  ];

  environment.systemPackages = with pkgs; [
    aichat
    aider-chat
    claude-code
    local.claude-code-router
    local.container-use
    code-cursor
    fabric-ai
    gemini-cli
    goose-cli
    files-to-prompt
    llm.withAllPlugins
    lmstudio # to try, open-webui-like?
    # Not really used: local.magic-cli
    local.mcp-inspector
    local.mcptools
    mods # pipe command output to a question
    n8n
    openai-whisper
    pandoc # Test html -> markdown
    local.playwright-mcp
    repomix # Testing
    local.ofc
    # Not really using, asks for openai key: shell-gpt # $ sgpt ...
    strip-tags
    task-master-ai
    tgpt # $ tgpt question
    local.ttok
    windsurf

    # Support tools
    argc
    jq
  ];
}
