{
  config,
  pkgs,
  ...
}: let
  version = "main-stable"; # TODO: sha
  dbuser = "litellm";
  dbname = "litellm";
  ociBackend = config.virtualisation.oci-containers.backend;
in {
  # Use the container version of litellm until https://github.com/NixOS/nixpkgs/issues/432925

  # TODO: use another network, or at least keep in sync with
  # the podman default network config.

  # Network borrowed from https://github.com/nifoc/dotfiles/blob/master/system/nixos/container.nix
  # For services that listen on podman0
  systemd.services.podman-wait-for-host-interface = {
    description = "Wait for podman0 to be available";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip address show podman0; do sleep 1; done'";
    };
  };

  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  services.postgresql.authentication = ''
    host litellm litellm 10.88.0.0/16 scram-sha-256
  '';

  networking.firewall.interfaces.podman0 = {
    allowedTCPPorts = [
      5432
    ];
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    ensureDatabases = [dbname];
    ensureUsers = [
      {
        name = dbuser;
        ensureDBOwnership = true;
        # TODO: set password manually
      }
    ];
  };

  sops.secrets.litellm = {};

  virtualisation.oci-containers.containers = {
    litellm = {
      image = "ghcr.io/berriai/litellm-non_root:${version}";
      ports = ["4000:4000"];
      environmentFiles = [
        config.sops.secrets.litellm.path
      ];
      volumes = [
        #        "${./litellm_license.py}:/app/litellm/proxy/auth/litellm_license.py:ro"
        "${./litellm_license.py}:/usr/lib/python3.13/site-packages/litellm/proxy/auth/litellm_license.py:ro"
      ];
    };
  };

  systemd.services = {
    "${ociBackend}-litellm" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };
  };
}
