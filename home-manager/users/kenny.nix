{
  lib,
  pkgs,
  config,
  ...
}:
# Also see 'features' and user to host mapping conversation: https://claude.ai/chat/6905ef21-91d0-413d-bd71-06a6ca4e87b7
let
  secretNames = [
    "DEEPSEEK_API_KEY"
    "ZAI_API_KEY"
  ];
  secret = name: "$(cat ${config.sops.secrets.${name}.path})";
  secretAttrs =
    builtins.listToAttrs
    (map (n: {
        name = n;
        value = {};
      })
      secretNames);
  secretVars =
    builtins.listToAttrs
    (map (n: {
        name = n;
        value = secret n;
      })
      secretNames);
in {
  sops.age.keyFile = "/home/kenny/.home-manager.key";
  sops.defaultSopsFile = ./kenny-secrets.yaml;
  sops.secrets = secretAttrs;

  home.sessionVariables.DEEPSEEK_API_KEY = secret "DEEPSEEK_API_KEY";
  home.sessionVariables.ZAI_API_KEY = secret "ZAI_API_KEY";
  home.sessionVariables.ZAI_CODING_API_KEY = secret "ZAI_API_KEY";

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

  # Editor
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = false;
    # TODO move most of rest of `common.nix`
    # extraConfig = '' ... '' & extraLuaConfig = '' ... ''
    plugins = with pkgs.vimPlugins; [
      bufferline-nvim # line at the top with file names
      snacks-nvim
      # LazyVim will handle most plugins
      # LazyVim
      # lazy-nvim
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
    # TODO migrate local config to here
    # For an example see: https://github.com/Alper-Celik/MyConfig/blob/2c6803c102f45321300d18898738f6efcdd024fe/Configs/Kitty.home.nix#L10
  };

  # Zed
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

  home = {
    packages = with pkgs; [
      hello
    ];

    username = "kenny";
    homeDirectory = "/home/kenny";

    stateVersion = "25.05";
  };
}
