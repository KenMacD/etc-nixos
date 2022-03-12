{ config, lib, pkgs, ... }:

with lib;

{
  ########################################
  # Nix
  ########################################
  system.stateVersion = "20.09";
  nix.settings.auto-optimise-store = mkDefault true;
  nixpkgs.config.allowUnfree = true;

  # Include current config:
  environment.etc.current-nixos-config.source = ./.;

  # Include a full list of installed packages
  environment.etc.current-system-packages.text = let
    packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in formatted;

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
  boot.loader.efi.canTouchEfiVariables = mkDefault true;
  boot.tmpOnTmpfs = mkDefault true;

  # ZFS doesn't like hibernate apparently. See:
  #  * https://nixos.wiki/wiki/NixOS_on_ZFS#Known_issues
  #  * https://github.com/openzfs/zfs/issues/260
  boot.kernelParams = mkIf config.boot.zfs.enabled [
    "nohibernate"
  ];

  ########################################
  # Network
  ########################################
  networking.firewall.enable = true;
  networking.useDHCP = false; # deprecated
  networking.usePredictableInterfaceNames = false;
  services.avahi = {
    enable = true;
  };
  # From https://nixos.wiki/wiki/Printing
  services.avahi.nssmdns = false; # Use the settings from below
  # settings from avahi-daemon.nix where mdns is replaced with mdns4
  system.nssModules = with pkgs.lib; optional (!config.services.avahi.nssmdns) pkgs.nssmdns;
  system.nssDatabases.hosts = with pkgs.lib; optionals (!config.services.avahi.nssmdns) (mkMerge [
    (mkOrder 900 [ "mdns4_minimal [NOTFOUND=return]" ]) # must be before resolve
    (mkOrder 1501 [ "mdns4" ]) # 1501 to ensure it's after dns
  ]);

  ########################################
  # User
  ########################################
  programs.fish.enable = true;
  programs.vim.defaultEditor = true;
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
  services.chrony = {
    enable = true;
    enableNTS = true;
  };
  networking.timeServers = [ "time.nrc.ca" ];
  # Override systemd config with https://github.com/NixOS/nixpkgs/pull/104944
  # - hardcode paths, mkforce protectsystem
  systemd.services.chronyd.serviceConfig = {
    KeyringMode = "private";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateMounts = "yes";
    PrivateTmp = "yes";
    ProtectControlGroups = true;
    ProtectHome = "yes";
    ProtectHostname = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectSystem = mkForce "strict";
    ReadWritePaths = [ "/var/run/chrony" "/var/lib/chrony" ];
    RemoveIPC = true;
    RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallFilter = "@system-service @clock";
    SystemCallArchitectures = "native";

    # even though in the default configuration chrony does not access the rtc clock,
    # it may be configured to so so either with the 'rtcfile' configuration option
    # or using the '-s' flag. so we make sure rtc devices can still be used by it.
    # at the same time there is no need for chrony to access any other device types.
    DeviceAllow = "char-rtc";
    DevicePolicy = "closed";
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [ ];

}
