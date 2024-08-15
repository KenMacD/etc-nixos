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
  system.stateVersion = "23.05";
  nix = {
    settings.auto-optimise-store = mkDefault true;
    settings.trusted-users = mkDefault ["root" "@wheel"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # after https://github.com/NixOS/nix/pull/8323 and/or https://github.com/NixOS/nix/pull/3494
    #   print-build-logs = true
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      keep-going = true
      connect-timeout = 1
    '';

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (import ./unfree.nix);

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
      ${inputs.nixos-needsreboot.packages.${system}.default}/bin/nixos-needsreboot || true
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

  # Use the latest released kernel
  # bcachefs overrides with mkDefault as well
  boot.kernelPackages = mkOverride 999 pkgs.linuxPackages_6_9;
  security.unprivilegedUsernsClone = mkDefault config.virtualisation.containers.enable;

  # Limit previous generations to avoid /boot filling up
  boot.loader.systemd-boot.configurationLimit = mkDefault 50;
  boot.loader.efi.canTouchEfiVariables = mkDefault true;
  boot.tmp.useTmpfs = mkDefault true;

  # Clean up old coredumps
  systemd = {
    services.clear-log = {
      description = "Clear old coredumps";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=14d";
      };
    };
    timers.clear-log = {
      wantedBy = ["timers.target"];
      partOf = ["clear-log.service"];
      timerConfig.OnCalendar = "weekly UTC";
    };
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
  users.users.kenny = {
    isNormalUser = true;
    uid = 1000;
    createHome = true;
    shell = pkgs.fish;
    extraGroups = ["wheel"];

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
  services.timesyncd.enable = true;
  networking.timeServers = ["time.cloudflare.com"];

  ########################################
  # Programs
  ########################################
  programs.fish.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      packages.myPlugins = with pkgs.vimPlugins; {
        start = [
          lazy-nvim
          nvim-treesitter.withAllGrammars
          nvim-lastplace
          vim-gnupg
        ];
        opt = [];
      };
      customRC = ''
        " ignore case in search unless set
        set ignorecase
        set smartcase

        " No directory editing please
        for f in argv()
          if isdirectory(f)
            echomsg "vimrc: Cowardly refusing to edit directory " . f
            quit
          endif
        endfor
        if exists('g:vscode')
          " VSCode extension
        else
          " ordinary neovim
          " Disable mouse selections
          set mouse=
        endif

        " Enable treesitter and lazyvim
        lua << EOF
        require'nvim-treesitter.configs'.setup {
          highlight = {
            enable = true,
          },
        }
        require("lazy").setup()
        EOF

        " Show nbsp characters
        set listchars=nbsp:.

        " gopass
        au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile
      '';
    };
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    alejandra
    config.boot.kernelPackages.cpupower
    kitty.terminfo
  ];

  # Set RCLONE_FAST_LIST to always reduce costs
  # when sending files to B2.
  environment.variables.RCLONE_FAST_LIST = "1";
}
