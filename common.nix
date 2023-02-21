{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    modules/fish.nix  # Remove when https://github.com/NixOS/nixpkgs/pull/176886
  ];

  ########################################
  # Nix
  ########################################
  system.stateVersion = "22.11";
  nix = {
    settings.auto-optimise-store = mkDefault true;
    extraOptions = ''
      keep-going = true
    '';

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };
  nixpkgs.config.allowUnfree = true;

  # Disable command-not-found until proper Flake solution
  programs.command-not-found.enable = mkDefault false;

  # Include current config:
  environment.etc.current-nixos-config.source = ./.;

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
  # Limit previous generations to avoid /boot filling up
  boot.loader.systemd-boot.configurationLimit = mkDefault 10;
  boot.loader.efi.canTouchEfiVariables = mkDefault true;
  boot.tmpOnTmpfs = mkDefault true;

  ########################################
  # Disk
  ########################################
  services.fstrim.enable = mkDefault true;

  ########################################
  # Network
  ########################################
  networking.firewall.enable = mkDefault true;
  networking.useDHCP = false;  # deprecated
  networking.usePredictableInterfaceNames = mkDefault false;

  ########################################
  # User
  ########################################
  programs.fish.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  users.users.kenny = {
    isNormalUser = true;
    uid = 1000;
    createHome = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
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
    '';
  };
  services.openssh.passwordAuthentication = mkDefault false;
  services.openssh.kbdInteractiveAuthentication = mkDefault false;

  ########################################
  # Services
  ########################################
  # NTP
  services.timesyncd.enable = true;
  networking.timeServers = [ "time.cloudflare.com" ];

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [ ];

}
