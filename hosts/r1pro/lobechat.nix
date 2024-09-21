{config, ...}: let
  version = "1.19.0";
  # crane digest --full-ref -v docker.io/lobehub/lobe-chat:v
  hash = "sha256:ee4f366b6ce07693cae821f23b465eb9fdeb0b498a2b2bffd54cafc858d3bd9c";
in {
  ids.uids.lobechat = 912;
  ids.gids.lobechat = 912;

  users.users.lobechat = {
    isSystemUser = true;
    group = "lobechat";
    description = "Lobechat daemon user";
    uid = config.ids.uids.lobechat;
  };

  users.groups.lobechat = {
    gid = config.ids.gids.lobechat;
  };

  # NB: After changing the secrets needed to:
  # systemctl restart podman-lobechat-server.service
  # not sure why
  sops.secrets.lobechat = {};
  virtualisation.oci-containers.containers = {
    lobechat-server = {
      # https://lobehub.com/docs/self-hosting/environment-variables/basic
      environmentFiles = [
        config.sops.secrets.lobechat.path
      ];
      image = "docker.io/lobehub/lobe-chat:v${version}@${hash}";
      ports = ["3210:3210"];
    };
  };
}
