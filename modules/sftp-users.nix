{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  userOptions = {
    name,
    config,
    ...
  }: {
    options.sftpOnly = mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether user should only be allowed SFTP access";
    };

    config = mkIf config.sftpOnly {
      # Force non-login user:
      isSystemUser = true;
      isNormalUser = false;
      shell = pkgs.shadow;
      useDefaultShell = false;

      # Isolate to their own group:
      group = name;

      # Create their sftp dir, chroot'd in sshd
      home = "/srv/sftp/${name}/${name}";
      createHome = true;
    };
  };
  sftpUsers = filterAttrs (_: u: u.sftpOnly) config.users.users;
in {
  options = {
    users.users = mkOption {
      type = with types; attrsOf (submodule userOptions);
    };
  };

  config = mkIf (sftpUsers != {}) {
    users.groups = flip mapAttrs' sftpUsers (
      name: value:
        nameValuePair name {
          gid = value.uid;
        }
    );

    services.openssh = {
      allowSFTP = true;
      extraConfig = let
        allUserConfigs = flip mapAttrsToList sftpUsers (
          user: value: ''
            Match User ${user}

            ForceCommand internal-sftp -d %u

            ChrootDirectory ${dirOf value.home}

            AllowAgentForwarding no
            AllowTcpForwarding no
            X11Forwarding no
          ''
        );
      in ''
        ##############
        # SFTP Users #
        ##############
        ${concatStringsSep "\n" allUserConfigs}

        # Following rules should match all users again
        Match all
      '';
    };
  };
}
