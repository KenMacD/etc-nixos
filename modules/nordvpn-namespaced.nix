{
  config,
  lib,
  pkgs,
  self,
  system,
  ...
}:
with lib; let
  cfg = config.services.nordvpn-namespaced;
  local = self.packages.${system};

  mkVpnConfig = {
    auth-user-pass-path,
    tls-auth-path,
    remote,
    verify-x509-name,
  }: ''
    client
    dev tun
    proto tcp
    remote ${remote} 443
    resolv-retry infinite
    remote-random
    nobind
    tun-mtu 1500
    tun-mtu-extra 32
    mssfix 1450
    persist-key
    persist-tun
    ping 15
    ping-restart 0
    ping-timer-rem
    reneg-sec 0
    comp-lzo no
    verify-x509-name CN=${verify-x509-name}
    remote-cert-tls server
    auth-user-pass ${auth-user-pass-path}
    verb 3
    pull
    fast-io
    cipher AES-256-CBC
    auth SHA512
    ca ${./nordvpn-ca.crt}
    key-direction 1
    tls-auth ${tls-auth-path}
  '';
in {
  options.services.nordvpn-namespaced = {
    enable = mkEnableOption "Enable NordVPN";

    namespaces = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          remote = mkOption {
            type = types.str;
            description = "Remote server address";
            example = "192.0.2.1";
          };
          verify-x509-name = mkOption {
            type = types.str;
            description = "X509 name to verify";
            example = "ro123.nordvpn.com";
          };
          autoStart = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to start this VPN namespace automatically";
          };
        };
      });
      default = {};
      description = "VPN namespace configurations";
      example = literalExpression ''
        {
          romania = {
            remote = "192.0.2.1";
            verify-x509-name = "ro123.nordvpn.com";
            autoStart = false;  # Don't start automatically
          };
          usa = {
            remote = "192.0.2.2";
            verify-x509-name = "us123.nordvpn.com";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Validate that at least one namespace is configured
    assertions = [
      {
        assertion = cfg.namespaces != {};
        message = "At least one VPN namespace must be configured when nordvpn is enabled";
      }
    ];

    sops.secrets = {
      nordvpn-auth-user-pass = {
        sopsFile = ./nordvpn-secrets.yaml;
      };
      nordvpn-tls-auth = {
        sopsFile = ./nordvpn-secrets.yaml;
      };
    };

    systemd.services = let
      # Generate services for each namespace inside the config block
      mkNamespaceServices = namespaces:
        mapAttrs' (
          namespaceName: namespaceConfig:
            nameValuePair "namespaced-openvpn-${namespaceName}" (
              let
                vpnConfigFile = pkgs.writeText "nordvpn-${namespaceName}.ovpn" (mkVpnConfig {
                  auth-user-pass-path = config.sops.secrets.nordvpn-auth-user-pass.path;
                  tls-auth-path = config.sops.secrets.nordvpn-tls-auth.path;
                  remote = namespaceConfig.remote;
                  verify-x509-name = namespaceConfig.verify-x509-name;
                });
              in {
                description = "Network namespace ${namespaceName} using OpenVPN";
                wantedBy = mkIf namespaceConfig.autoStart ["multi-user.target"];
                requires = ["network-online.target"];
                after = ["network-online.target"];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = "${local.namespaced-openvpn}/bin/namespaced-openvpn --namespace ${namespaceName} --config ${vpnConfigFile}";
                  Restart = "on-failure";
                  RestartSec = "5s";
                  # Security hardening (TODO: add more)
                  ProtectSystem = "strict";
                  ProtectHome = true;
                  PrivateTmp = true;
                  ReadWritePaths = ["/etc/netns/"];
                };
              }
            )
        )
        namespaces;
    in
      mkNamespaceServices cfg.namespaces;
  };
}
