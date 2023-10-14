{ config, lib, pkgs, ... }:

# Ref: https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
let
  version = "1.81.1";
  dataDir = "/mnt/silver/immich";
  dbuser = "immich";
  dbname = "immich";
  dbpassword = "immich";
  ociBackend = config.virtualisation.oci-containers.backend;
  containersHost = "host.containers.internal";

  # cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
  typesenseApiKey = "ABCD";

  pgSuperUser = config.services.postgresql.superUser;

  immichBase = {
    environment = {
      NODE_ENV = "production";
      DB_HOSTNAME = containersHost;
      DB_PORT = toString config.services.postgresql.port;
      DB_USERNAME = dbuser;
      DB_PASSWORD = dbpassword;
      DB_DATABASE_NAME = dbname;
      REDIS_HOSTNAME = containersHost;
      REDIS_PORT = toString config.services.redis.servers.immich.port;
      REDIS_PASSWORD = "immich";

      TYPESENSE_API_KEY = typesenseApiKey;
      TYPESENSE_ENABLED = "true";
      TYPESENSE_HOST = "immich-typesense";

      LOG_LEVEL= "debug";

      IMMICH_WEB_URL = "https://immich.home.macdermid.ca";
      PUBLIC_IMMICH_SERVER_URL = "https://immich.home.macdermid.ca";
      # IMMICH_SERVER_URL = "http://immich-server:3001";
    };
    extraOptions = [
      "--uidmap=0:${toString config.ids.uids.immich}:1"
    ];
  };
in {

  # TODO: use another network, or at least keep in sync with
  # the podman default network config.

  # Network borrowed from https://github.com/nifoc/dotfiles/blob/master/system/nixos/container.nix
  # For services that listen on podman0
  systemd.services.podman-wait-for-host-interface = {
    description = "Wait for podman0 to be available";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

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
    ensureDatabases = [ dbname ];
    ensureUsers = [{
      name = dbuser;
      ensurePermissions."DATABASE ${dbname}" = "ALL PRIVILEGES";
    }];
  };

  services.redis.servers.immich = {
    enable = true;
    port = 31640;
    bind = "10.88.0.1 172.27.0.3";
#    user = "immich";
    requirePass = "immich";
  };
  systemd.services.redis-immich.after = [ "podman-wait-for-host-interface.service" ];

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
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    before = [
      "${ociBackend}-immich-server.service"
      "${ociBackend}-immich-microservices.service"
      "${ociBackend}-immich-machine-learning.service"
      "${ociBackend}-immich-web.service"
      "${ociBackend}-immich-proxy.service"
    ];
    wantedBy = [ "multi-user.target" ];
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
    immich-server = immichBase // {
      image = "ghcr.io/immich-app/immich-server:v${version}";
      ports = [ "3551:3001" ];
      entrypoint = "/bin/sh";
      cmd = [ "./start-server.sh" ];
      # dependsOn = [ "${ociBackend}-immich-typesense" ];
      dependsOn = [ "immich-typesense" ];
      volumes = [ "${dataDir}:/usr/src/app/upload" ];
    };

    immich-microservices = immichBase // {
      image = "ghcr.io/immich-app/immich-server:v${version}";
      entrypoint = "/bin/sh";
      # dependsOn = [ "${ociBackend}-immich-typesense" ];
      dependsOn = [ "immich-typesense" ];
      cmd = [ "./start-microservices.sh" ];
      volumes = [ "${dataDir}:/usr/src/app/upload" ];
    };

    immich-web = immichBase // {
      image = "ghcr.io/immich-app/immich-web:v${version}";
      ports = [ "3550:3000" ];
      entrypoint = "/bin/sh";
      cmd = [ "./entrypoint.sh" ];
    };

    immich-machine-learning = immichBase // {
      image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
      volumes = [ "immich-machine-learning-cache:/cache" ];
    };

    immich-typesense = {
      image = "typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd";

      environment = {
        TYPESENSE_API_KEY = typesenseApiKey;
	TYPESENSE_DATA_DIR = "/data";
      };
      extraOptions = [
        "--uidmap=0:${toString config.ids.uids.immich}:1"
      ];

      # Map volumes to host
      volumes = [ "immich-typesense:/data" ];
    };
  };

  systemd.services = {
    "${ociBackend}-immich-server" = {
      requires = [ "postgresql.service" "redis-immich.service" ];
      after = [ "postgresql.service" "redis-immich.service" ];
    };

    "${ociBackend}-immich-microservices" = {
      requires = [ "postgresql.service" "redis-immich.service" ];
      after = [ "postgresql.service" "redis-immich.service" ];
    };

    "${ociBackend}-immich-machine-learning" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
  };
}
