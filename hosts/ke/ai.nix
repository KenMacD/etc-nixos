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

  nix.settings.extra-substituters = ["https://numtide.cachix.org"];
  nix.settings.extra-trusted-public-keys = ["numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="];

  environment.etc."gemini-cli/system-defaults.json" = {
    text = builtins.toJSON {
      privacy = {
        usageStatisticsEnabled = false;
      };
    };
    mode = "0644";
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

  # For voxinput
  # https://github.com/richiejp/VoxInput/blob/02a6f03359a45aeaeefd7e43bf1b197c7b6eeff9/README.md?plain=1#L34
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0620", OPTIONS+="static_node=uinput"
  '';

  environment.systemPackages = with pkgs; [
    # TODO: broken 2026-02-25 local."@neuralnomads/codenomad"
    aichat
    nix-ai-tools.antigravity-cli
    local.byterover-cli
    local.cclimits # Check quota/usage for AI coding CLI tools
    local.cctx
    claude-code-router
    # TODO: creates dmesg noise local.container-use
    local.code-assistant-manager # TODO: try setting up skills/mcp with
    nix-ai-tools.codex
    code-cursor
    devin-desktop
    fabric-ai
    nix-ai-tools.fence
    goose-cli
    files-to-prompt
    (llm.withPlugins {
      llm-deepseek = true;
    })
    lmstudio # to try, open-webui-like?
    # Not really used: local.magic-cli
    local.mcptools
    mods # pipe command output to a question
    nix-ai-tools.openspec # To try: spec-first dev
    pandoc # Test html -> markdown
    local.playwright-mcp
    repomix # Testing
    # Not really using, asks for openai key: shell-gpt # $ sgpt ...
    local.spec-kit
    strip-tags
    # TODO: broken 2026-01-04 task-master-ai
    tgpt # $ tgpt question
    local.ttok
    local.tvly
    voxinput

    # CLI Code Agents
    codex
    happy-coder # Hook claude code to mobile
    nix-ai-tools.crush
    nix-ai-tools.forgecode
    nix-ai-tools.droid
    local.octofriend
    nix-ai-tools.opencode
    opencode-desktop
    nix-ai-tools.pi
    local.acpx # Headless ACP client to drive agents ($ acpx)
    nix-ai-tools.zcode

    # Support tools
    nix-ai-tools.agent-browser
    argc
    nix-ai-tools.ck # Local first semantic and hybrid BM25 grep / search
    jq

    # MCP
    local.alph-cli # Manage MCPs
    local.chrome-devtools-mcp
    local.dbhub
    local.firefox-devtools-mcp
    local.mcp2cli
    # TODO: broken 2026-02-25 local."@upstash/context7-mcp" # context7's mcp (to avoid 'Error: SSE stream disconnected: TypeError: terminated')
    # TODO: broken 2026-02-25 local."@z_ai/mcp-server" # ZAI's Vision MCP Server
    mcp-nixos
    local.mcp-server-tree-sitter

    # Voice
    whisper-cpp-vulkan

    # Testing
    nix-ai-tools.agentsview
  ];
}
