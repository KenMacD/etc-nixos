{
  self,
  config,
  pkgs,
  lib,
  system,
  modulesPath,
  ...
}: let
  local = self.packages.${system};
in {
  imports = [
    ./hardware.nix
    ./networkd.nix
  ];

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;
  hardware = {};

  ########################################
  # Secrets
  ########################################
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.kanidm-tls-chain = {
    owner = "kanidm";
    group = "kanidm";
  };
  sops.secrets.kanidm-tls-key = {
    owner = "kanidm";
    group = "kanidm";
  };
  sops.secrets.cloudflare-tunnel = {};

  ########################################
  # Nix
  ########################################
  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
    extra-substituters = [
      # default priority is 40, lower = checked first
      # For pre-built n8n and zerotier packages
      "https://nix-community.cachix.org?priority=50"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # More limited disk size so clean up sooner
  nix.gc.options = "--delete-older-than 10d";

  ########################################
  # Boot
  ########################################
  # CX23 is BIOS-only (confirmed via efibootmgr), so use GRUB not systemd-boot.
  # Must explicitly disable systemd-boot because common.nix sets it as mkDefault true.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = lib.mkForce ["/dev/sda"];
  boot.loader.grub.configurationLimit = 2;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "hz";
    useNetworkd = true;
    networkmanager.enable = false;
    timeServers = [
      "ntp1.hetzner.de"
      "ntp2.hetzner.com"
      "ntp3.hetzner.net"
    ];
  };
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [config.services.tailscale.interfaceName];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
    allowedTCPPorts = [];
  };

  ########################################
  # Services
  ########################################
  services.tailscale.enable = true;

  # Tailscale config current done manually with commands like:
  # * tailscale login
  # * tailscale serve --service=svc:agent-zero --https=443 http://10.88.0.10:4000
  # * tailscale serve --service=svc:agent-zero --tcp=22 tcp://10.88.0.10:22

  # Force tailscaled to use nftables (critical for clean nftables-only systems)
  # Avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  services.kanidm = {
    # Before upgrade test: sudo -u kanidm -g kanidm kanidmd domain upgrade-check
    package = pkgs.kanidm_1_10;
    server = {
      enable = true;
      settings = {
        version = "2"; # Required to set x-forward-for
        bindaddress = "127.0.0.1:9001";
        ldapbindaddress = "127.0.0.1:636";
        origin = "https://auth.macdermid.ca";
        domain = "auth.macdermid.ca";
        # log_level = "debug";
        tls_chain = config.sops.secrets.kanidm-tls-chain.path;
        tls_key = config.sops.secrets.kanidm-tls-key.path;
        # hz will sit behind a cloudflared tunnel (loopback) like r1pro.
        http_client_address_info.x-forward-for = ["127.0.0.1"];
      };
    };
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "hz" = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
        default = "http_status:404";
      };
    };
  };
  systemd.services.cloudflared-tunnel-hz = {
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      RestartSec = "30s";
    };
  };

  zramSwap.enable = true;

  ########################################
  # Virtualisation
  ########################################
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.agent-zero = {
    image = "docker.io/agent0ai/agent-zero:v2.2";
    pull = "always";
    volumes = ["agent-zero-data:/a0/usr"];
    extraOptions = [
      # Static IP for tailscale forwarding
      "--ip=10.88.0.10"
    ];
  };
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      dns_enabled = true;
      subnets = [
        # Use /24 with 100-200 for dynamic
        {
          subnet = "10.88.0.0/24";
          gateway = "10.88.0.1";
          lease_range = {
            start_ip = "10.88.0.100";
            end_ip = "10.88.0.200";
          };
        }
      ];
    };
  };

  ########################################
  # User
  ########################################
  users.motd = ''
  '';

  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
  ];
}
