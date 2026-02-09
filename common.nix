{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
with lib; {
  imports = [
    modules/default.nix
    modules/env.nix # Set XDG/config vars
    modules/sway-desktop.nix # My sway desktop configuration
  ];

  ########################################
  # Nix
  ########################################
  system.stateVersion = mkDefault "25.05";
  nix = {
    settings = {
      auto-allocate-uids = true;
      auto-optimise-store = mkDefault true;
      connect-timeout = mkDefault 2;
      experimental-features = [
        "auto-allocate-uids"
        # "ca-derivations"
        "cgroups"
        "nix-command"
        "flakes"
      ];
      flake-registry = mkDefault ""; # instead of https://channels.nixos.org/flake-registry.json
      keep-going = mkDefault true;
      trusted-users = mkDefault ["root" "@wheel"];
      use-cgroups = mkDefault true;
      use-xdg-base-directories = true;
      # warn-dirty = mkDefault false;
      #
      # allow-import-from-derivation = false;
      #
      # after https://github.com/NixOS/nix/pull/8323 and/or https://github.com/NixOS/nix/pull/3494
      #   print-build-logs = true
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    channel.enable = mkDefault false;
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (import ./unfree.nix);
  systemd.services."nix-daemon".serviceConfig = {
    # It'd be nice if this could be 50% of all CPUs
    # Re: https://github.com/systemd/systemd/issues/33136
    CPUQuota = "200%";
    ManagedOOMMemoryPressure = "kill";
    ManagedOOMMemoryPressureLimit = "80%";
  };

  # Disable building man-cache as it's slow, slightly
  # lower than default of 1000
  documentation.man.generateCaches = mkOverride 999 false;

  # Include current config:
  environment.etc.current-nixos-config.source = ./.;

  # From: github:etu/nixconfig/modules/base/default.nix
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      NO_FORMAT="\033[0m"
      F_BOLD="\033[1m"
      C_LIME="\033[38;5;10m"

      if test -e /run/current-system; then
        echo -e "''${F_BOLD}''${C_LIME}==> diff to current-system ''${NO_FORMAT}"
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
      fi

      echo -e "''${F_BOLD}''${C_LIME}==> Indicate if a reboot is needed or not ''${NO_FORMAT}"
      ${pkgs.nixos-needsreboot}/bin/nixos-needsreboot || true
    '';
  };

  ########################################
  # Hardware
  ########################################
  hardware.cpu.intel.updateMicrocode = mkDefault true;

  ########################################
  # Locale
  ########################################
  time.timeZone = mkDefault "America/Halifax";
  i18n.defaultLocale = mkDefault "en_CA.UTF-8";

  ########################################
  # Boot
  ########################################
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = mkDefault true;

  boot.kernelPackages = mkOverride (lib.modules.defaultOrderPriority - 1) pkgs.linuxPackages_6_18;
  security.unprivilegedUsernsClone = mkDefault config.virtualisation.containers.enable;

  boot.kernel.sysctl = {};

  # Limit previous generations to avoid /boot filling up
  boot.loader.systemd-boot.configurationLimit = mkDefault 10;
  boot.loader.efi.canTouchEfiVariables = mkDefault true;
  boot.tmp.useTmpfs = mkDefault true;

  # Clean up old coredumps
  systemd.services.clear-log = {
    description = "Clear old coredumps";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=14d";
    };
  };
  systemd.timers.clear-log = {
    wantedBy = ["timers.target"];
    partOf = ["clear-log.service"];
    timerConfig.OnCalendar = "weekly UTC";
  };

  ########################################
  # Disk
  ########################################
  services.fstrim.enable = mkDefault true;

  ########################################
  # Network
  ########################################
  networking.firewall.enable = mkDefault true;
  networking.useDHCP = false; # deprecated
  networking.usePredictableInterfaceNames = mkDefault false;

  ########################################
  # User
  ########################################
  # Enumerate all systems uids here:
  ids.uids = {
    kenny = 1001;
    angela = 1002;

    media = 1201;

    sftp-yoga = 1301;
  };
  users.defaultUserShell = pkgs.fish;
  users.users.kenny = {
    isNormalUser = true;
    uid = config.ids.uids.kenny;
    createHome = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "wpa_supplicant" # For wifi config
      "uinput" # For testing kanata
      "tss" # Testing tpm2
    ];

    # Podman runs out of subuids with large images (eg connectedhomeip)
    subUidRanges = [
      {
        startUid = 100000;
        count = 1048576;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 1048576;
      }
    ];

    # TODO: look at https://www.openssh.com/agent-restrict.html to see about
    # limiting key to pam access without allowing it to be used to connect
    # to further hosts
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxdqQrcKwakfrGvXCRQ2mNM3c5CkbwSEMuUufIcO0Op0xJJkdb59v2iqkztZMNpJFbS61ymsyzeRCwDQ5xptUNrjvbnppL+tBzErKMdilHzadpLeGffUCJg9GcIVJxQzFVbt0tIGwPsBcVHb1WITmzQCoZ/O0p1NSFRovwU8TXCOhnuObDUisFiJyA2e3C8tNvlm0Rvgb7bIH0T+/W4VIc+7ZZWwP/UMCnBHE4azZAcDJ4e9XO+ZJwg6iUXu7lk5X+34ACeHkPu133cGesz8BMl7yoXT058RcEW5bfcN6Dpl/IODNjxbDeQ/dYiVNnSExUWOrCo1sN1RYUQrKCzCzqCZ+29A07czYJDPjUt8pZdBQV3z261zYqyeP/IOgdHp3LZobIm48XF/+Abp/tTu8e99TP1y3L+8XuAMeu1THwHdcnQLJgv4nGExXijlvI/NlPEWhDqs991hhD7eHkg9w7QfuTjxRvZIjAkeK7ByWqMTULMrQBeHSS095b0gdHG3PEGz9BW9J4gHxW/s/pa5Cya3AOv7DJPDAEgxjqhB4wAuzvNnuxNXZCBwrNr8rRr860eNsOOe1rilSKRojF5s2DRin5OzXxJGQkHb1lndxya6E2U5i/+PzGuuPxNmoRDMZ43z7FZWIFej6Vb6Xd1bc1Q8Izbg5M2ZXVgDVoUrY02Q=="
    ];
  };

  ########################################
  # Security
  ########################################
  security.sudo = {
    execWheelOnly = true;
    extraConfig = ''
      Defaults  env_keep += "BORG_KEYS_DIR"

      # Allow yubikey auth for sudo:
      Defaults  env_keep += "SSH_AUTH_SOCK"
      Defaults  env_keep += "GPG_TTY"
      Defaults  env_keep += "GNUPGHOME"
    '';
  };
  services.openssh.settings.PasswordAuthentication = mkDefault false;
  services.openssh.settings.KbdInteractiveAuthentication = mkDefault false;
  # Allow more than the default 1024 open files
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "16384";
    }
  ];

  ########################################
  # Services
  ########################################
  # NTP
  services.timesyncd.enable = mkDefault true;
  networking.timeServers = mkDefault ["time.cloudflare.com"];

  # fwupd disable p2p by default
  services.fwupd.daemonSettings = {
    P2pPolicy = mkDefault "nothing";
  };

  ########################################
  # Programs
  ########################################
  # TODO: look at other from https://github.com/arlohb/nixos/blob/910916a5e94b6192505a7535e071b7d025ac040c/conf/shell.nix#L37
  programs.git.config = {
    init.defaultBranch = "main";
    url."https://github.com/".insteadOf = ["gh:" "github:"];
  };
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      function whichreal
        readlink (which $argv)
      end

      if set -q KITTY_INSTALLATION_DIR
          set --global KITTY_SHELL_INTEGRATION enabled
          source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
          set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
      end
    '';
  };
  # TODO: probably move to a separate module
  # TODO: 0.11 adds vim.lsp.config()/vim.lsp.enable(), see if nixos uses
  # https://gpanders.com/blog/whats-new-in-neovim-0-11/
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    configure = {
      packages.myPlugins = with pkgs.vimPlugins; {
        # To maybe try:
        # vim-easymotion
        # vim-json
        # vim-yaml
        # telescope
        # vim-clap
        start = [
          editorconfig-vim # Settings in .editorconfig
          leap-nvim
          nerdtree # File path browsing
          nvim-cmp
          nvim-treesitter.withAllGrammars
          nvim-lastplace
          vim-sleuth
          vim-buffergator # <leader>b to show buffers
          vim-gnupg

          # Snippet
          cmp_luasnip
          luasnip
          friendly-snippets
        ];
        opt = [];
      };
      # Use https://github.com/nix-community/nixvim ?
      customRC = ''
        " Function to source files if they exist
        function! SourceIfExists(file)
          if filereadable(expand(a:file))
            exe 'source' a:file
          endif
        endfunction

        " ignore case in search unless set
        set ignorecase
        set smartcase

        " No directory editing please
        " For some reason this isn't printing in NixOS/nvim. Not sure why
        for f in argv()
          if isdirectory(f)
            echomsg "vimrc: Cowardly refusing to edit directory " . f
            quit
          endif
        endfor

        " Use the system clipboard
        set clipboard+=unnamedplus
        vnoremap <C-c> "+y

        " Show nbsp characters
        set listchars=nbsp:.

        " gopass
        au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile

        " Enable treesitter
        lua << EOF
          require'nvim-treesitter'.setup {
            highlight = {
              enable = true,
            },
          }
          -- 's' then two chars to jump to that
          vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
          vim.keymap.set('n',             'S', '<Plug>(leap-from-window)')

          local cmp = require('cmp')
          local luasnip = require('luasnip')

          -- Load friendly-snippets if installed
          require('luasnip.loaders.from_vscode').lazy_load()

          cmp.setup({
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = false }), -- select = false to avoid adding entry on just enter alone
              ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
              { name = 'buffer' },
              { name = 'path' },
            }),
          })

        EOF

        " Call user inits
        let $MYVIMRC = expand('$XDG_CONFIG_HOME/nvim/init.vim')
        call SourceIfExists("$MYVIMRC")

        let $MYVIMLUA = expand('$XDG_CONFIG_HOME/nvim/init.lua')
        call SourceIfExists("$MYVIMLUA")
      '';
    };
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    config.boot.kernelPackages.cpupower
    kitty.terminfo

    # Nix build packages
    alejandra
    git
    gitui
    just
  ];
  system.extraDependencies = [
    pkgs.nixVersions.stable # Always keep a stable nix version in the store
  ];

  # Set RCLONE_FAST_LIST to always reduce costs
  # when sending files to B2.
  environment.variables.RCLONE_FAST_LIST = "1";

  # Set SSL_CERT_FILE to avoid issues, expecially with 'uv run' python code
  environment.variables.SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
}
