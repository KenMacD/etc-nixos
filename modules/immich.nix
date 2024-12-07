{
  self,
  config,
  lib,
  pkgs,
  system,
  ...
}:
# Ref: https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
let
  version = "1.106.4";
  dataDir = "/mnt/easy/immich";
  dbuser = "immich";
  dbname = "immich";
  dbpassword = "immich";
  ociBackend = config.virtualisation.oci-containers.backend;
  containersHost = "host.containers.internal";

  pgSuperUser = config.services.postgresql.superUser;

  immichBase = {
    environment = {
      NODE_ENV = "production";
      DB_HOSTNAME = containersHost;
      DB_PORT = toString config.services.postgresql.settings.port;
      DB_USERNAME = dbuser;
      DB_PASSWORD = dbpassword;
      DB_DATABASE_NAME = dbname;
      REDIS_HOSTNAME = containersHost;
      REDIS_PORT = toString config.services.redis.servers.immich.port;
      REDIS_PASSWORD = "immich";

      LOG_LEVEL = "debug";

      IMMICH_WEB_URL = "https://immich.home.macdermid.ca";
      PUBLIC_IMMICH_SERVER_URL = "https://immich.home.macdermid.ca";
      # IMMICH_SERVER_URL = "http://immich-server:3001";
    };
  };
in {
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
    host immich immich 10.88.0.0/16 scram-sha-256
  '';

  networking.firewall.interfaces.podman0 = {
    allowedTCPPorts = [
      5432
      config.services.redis.servers.immich.port
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
      }
    ];

    # For 0.91.0:
    # TODO: should be an input
    extensions = [(self.packages.${system}.pgvecto-rs.override {postgresql = config.services.postgresql.package;})];
    settings = {shared_preload_libraries = "vectors";};
  };

  services.redis.servers.immich = {
    enable = true;
    port = 31640;
    bind = "10.88.0.1 172.27.0.3";
    requirePass = "immich";
  };
  systemd.services.redis-immich.after = ["podman-wait-for-host-interface.service"];

  ids.uids.immich = 911;
  ids.gids.immich = 911;

  users.users.immich = {
    isSystemUser = true;
    group = "immich";
    description = "Immich daemon user";
    #      home = cfg.dataDir;
    uid = config.ids.uids.immich;
  };

  users.groups.immich = {
    gid = config.ids.gids.immich;
  };

  systemd.services.immich-init = {
    enable = true;
    description = "Set up paths";
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
    before = [
      "${ociBackend}-immich-server.service"
      "${ociBackend}-immich-machine-learning.service"
    ];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.sudo}/bin/sudo -u immich \
        ${pkgs.postgresql}/bin/psql postgres \
        -c "alter user immich with password 'immich'"
    '';
  };
  virtualisation.oci-containers.containers = {
    immich-server =
      immichBase
      // {
        image = "ghcr.io/immich-app/immich-server:v${version}";
        ports = ["3550:3001"];
        volumes = [
          "${dataDir}:/usr/src/app/upload"
          "/dev/bus/usb:/dev/bus/usb"
        ];
        extraOptions = [
          "--uidmap=0:${toString config.ids.uids.immich}:1"
          "--add-host=auth.home.macdermid.ca:host-gateway"
        ];
      };

    immich-machine-learning =
      immichBase
      // {
        image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
        volumes = ["immich-machine-learning-cache:/cache"];
        extraOptions = [
          "--uidmap=0:${toString config.ids.uids.immich}:1"
          "--device-cgroup-rule"
          "c 189:* rmw"
          "--device=/dev/dri:/dev/dri"
        ];
      };
  };

  systemd.services = {
    "${ociBackend}-immich-server" = {
      requires = ["postgresql.service" "redis-immich.service"];
      after = ["postgresql.service" "redis-immich.service"];
    };

    "${ociBackend}-immich-machine-learning" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };
  };
}
