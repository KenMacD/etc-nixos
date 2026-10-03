{
  lib,
  pkgs,
  config,
  ...
}:
# Also see 'features' and user to host mapping conversation: https://claude.ai/chat/6905ef21-91d0-413d-bd71-06a6ca4e87b7
# TODO: anything from https://github.com/YuntaoLincs/nixos_config/blob/2551d278eb3e8a882c03c35076a9a902af05f01b/home.nix#L152 (general home-manager ideas)
let
  # Secret names shared between sops.secrets and home.sessionVariables.
  secretNames = [
    "DEEPSEEK_API_KEY"
    "ZAI_API_KEY"
  ];
  secret = name: "$(cat ${config.sops.secrets.${name}.path})";
in {
  ## Home basics

  home = {
    username = "kenny";
    homeDirectory = "/home/kenny";
    stateVersion = "25.05";

    packages = with pkgs; [
      hello
    ];
  };

  ## Secrets

  # TODO: move things to a secret key from the system config... maybe
  sops.age.keyFile = "/home/kenny/.home-manager.key";
  sops.defaultSopsFile = ./kenny-secrets.yaml;
  sops.secrets = lib.genAttrs secretNames (_: {});

  ## Session variables

  home.sessionVariables =
    (lib.genAttrs secretNames secret)
    // {
      ZAI_CODING_API_KEY = secret "ZAI_API_KEY";

      # Geedee Telemetry
      AGENTSVIEW_TELEMETRY_ENABLED = "0";
      TELEMETRY_ENABLED = "0";

      # Apply a patch to upstream that sets this
      PI_SKIP_VERSION_CHECK = "1";

      PYTHONDONTWRITEBYTECODE = "1";
    };

  ## Shell

  # TODO: migrate fish config
  programs.fish.enable = true;

  programs.fzf.enableFishIntegration = true;

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = ["--disable-up-arrow"];
    forceOverwriteSettings = true;
    settings = {
      ai = {
        enabled = true;
      };
      filter_mode_shell_up_key_binding = "session";
      history_filter = [
        "^cd "
        "^ls "
        "^z "
      ];
      search_mode = "daemon-fuzzy";
      update_check = false;
    };
    daemon.enable = true;
  };

  ## Editors (terminal)

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = false;
    # TODO: move most of rest of `common.nix`
    # extraConfig = '' ... '' & extraLuaConfig = '' ... ''
    # LazyVim will handle most plugins
    plugins = with pkgs.vimPlugins; [
      bufferline-nvim # line at the top with file names
      snacks-nvim
    ];
    initLua = ''
      -- Use the system clipboard and copy on ctrl+c
      vim.api.nvim_set_option("clipboard", "unnamedplus")
      vim.keymap.set('v', '<C-c>', 'y')
    '';
  };

  programs.kitty = {
    enable = true;
    extraConfig = ''
      include kitty-local.conf
    '';
    # TODO: migrate local config to here
    # For an example see: https://github.com/Alper-Celik/MyConfig/blob/2c6803c102f45321300d18898738f6efcdd024fe/Configs/Kitty.home.nix#L10
  };

  ## Zed

  # TODO: anything else from https://github.com/Quik95/dotfiles/blob/94e90fcdc7c82b3f70c7295c728e43673f077f1b/home-manager/modules/ide/zed.nix
  programs.zed-editor = {
    enable = true;

    # This populates the userSettings "auto_install_extensions"
    extensions = [
      "dockerfile"
      "elixir"
      "erlang"
      "git-firefly"
      "haskell"
      "html"
      "make"
      "mcp-server-container-use"
      "mcp-server-context7"
      "nix"
      "pylsp"
      "sql"
      "terraform"
      "toml"
      "vscode-great-icons"
    ];

    userSettings = {
      # From settings.json
      autosave = "on_focus_change";
      base_keymap = "VSCode";
      vim_mode = true;
      ui_font_size = 21;
      buffer_font_size = 21;
      theme = {
        mode = "system";
        light = "Gruvbox Dark Soft";
        dark = "One Dark";
      };

      agent = {
        inline_assistant_model = {
          provider = "zed.dev";
          model = "claude-sonnet-4-thinking";
        };
        default_profile = "write";
        default_model = {
          provider = "openrouter";
          model = "openrouter/auto";
        };
      };

      agent_servers = {
        gemini = {
          ignore_system_version = false;
        };
      };

      context_servers = {
        "mcp-server-context7" = {
          enabled = true;
          settings = {
            default_minimum_tokens = "10000";
          };
        };
        "container-use-mcp" = {
          enabled = true;
          settings = {};
        };
      };

      features = {
        edit_prediction_provider = "zed";
      };

      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
          formatter = {
            external = {
              command = "alejandra";
              arguments = [
                "--quiet"
              ];
            };
          };
          format_on_save = "on";
        };
        Rust = {
          language_servers = [
            "rust-analyzer"
          ];
        };
      };

      lsp = {
        nixd = {
          binary.path = "${pkgs.nixd}/bin/nixd";
          settings.formatting.command = ["${pkgs.alejandra}/bin/alejandra" "--"];
        };
        json-language-server.binary = {
          path = "${pkgs.vscode-json-languageserver}/bin/vscode-json-language-server";
          arguments = ["--stdio"];
        };
        rust-analyzer.binary.path = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        hls = {
          initialization_options = {
            haskell = {
              formattingProvider = "fourmolu";
            };
          };
        };
      };
    };
  };

  ## Package manager supply-chain policy

  # Slow-roll recently published package versions across JS/Python tooling.
  # TODO: add more from https://nesbitt.io/2026/03/04/package-managers-need-to-cool-down.html

  xdg.configFile = {
    # ~/.config/uv/uv.toml
    "uv/uv.toml".source = (pkgs.formats.toml {}).generate "uv.toml" {
      exclude-newer = "7 days";
    };

    # ~/.bunfig.toml (seconds)
    ".bunfig.toml".source = (pkgs.formats.toml {}).generate ".bunfig.toml" {
      install.minimumReleaseAge = 604800;
    };

    # ~/.config/pnpm/rc (minutes)
    "pnpm/rc".text = ''
      node-linker=hoisted
      minimum-release-age=10080
    '';
  };

  # ~/.npmrc (days)
  home.file.".npmrc".text = ''
    min-release-age=7
    ignore-scripts=true
    prefer-offline=true
    prefix="/home/kenny/.npm-packages"
  '';

  # TODO: pip has no config equivalent yet. In pip 26.0 you must compute the
  # date manually, e.g. --uploaded-prior-to="$(date -u -d '3 days ago' '+%Y-%m-%dT%H:%M:%SZ')".
  # In pip 26.1 (April 2026) it will support ISO-8601 durations like uv
  # (--uploaded-prior-to=P3D), settable via env vars or config files like all pip options.
}
