{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.plandex;

  inherit
    (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    types
    ;
in {
  options = {
    services.plandex = {
      enable = mkEnableOption "Plandex service";
      package = mkPackageOption pkgs "plandex-server" {};

      port = mkOption {
        default = 8016;
        type = types.port;
      };

      environment = {
        extra = mkOption {
          type = types.attrs;
          description = "Extra environment variables to pass run Plandex's server with. See Plandex documentation.";
          default = {};
          example = {
            GOENV = "development";
          };
        };
        file = mkOption {
          type = types.nullOr types.path;
          description = "Systemd environment file to add to Plandex.";
          default = null;
        };
      };

      database = {
        createLocally = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Create the database and database user locally.
          '';
        };

        uri = mkOption {
          type = types.nullOr types.str;
          description = ''
            Connection URI to the database, if not local.
          '';
          default = null;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      # TODO: if db create local then URI should not be set
    ];

    services.postgresql = mkIf cfg.database.createLocally {
      enable = true;
      ensureUsers = [
        {
          name = "plandex";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["plandex"];
    };

    systemd.services.plandex = {
      description = "Plandex - AI Driven Developement server.";
      after = ["network.target"] ++ lib.optionals cfg.database.createLocally ["postgresql.service"];
      wantedBy = ["multi-user.target"];
      requires = lib.optionals cfg.database.createLocally ["postgresql.service"];

      environment =
        {
          HOME = "/var/lib/plandex";
          PLANDEX_BASE_DIR = "/var/lib/plandex";
          PORT = toString cfg.port;
          GOENV = "development"; # TODO: make configurable
          DATABASE_URL =
            if cfg.database.uri != null
            then cfg.database.uri
            else (mkIf (cfg.database.createLocally) "postgres:///plandex?host=/run/postgresql&user=plandex");
            # TODO: set SMTP env vars
        }
        // cfg.environment.extra;

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        StateDirectory = "plandex";
        RuntimeDirectoryMode = "0700";
        DynamicUser = true;
        EnvironmentFile = lib.mkIf (cfg.environment.file != null) cfg.environment.file;
        # TODO: harden
      };
    };
  };
  meta.maintainers = [];
}
