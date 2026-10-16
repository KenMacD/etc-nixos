{
  self,
  config,
  pkgs,
  lib,
  system,
  ...
}: let
  local = self.packages.${system};

  # tailscaled being "active" only means the daemon started, not that the node
  # is logged in; tailscale-serve-* units gate on actual connectivity.
  waitTailscale = pkgs.writeShellScriptBin "wait-tailscale-connected" ''
    for i in $(seq 1 60); do
      if ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; then
        exit 0
      fi
      sleep 1
    done
    echo "wait-tailscale-connected: tailscale not up after 60s" >&2
    exit 1
  '';
in {
  imports = [
    ./networkd.nix

    ./../../modules/litellm.nix
    ./../../modules/paperclip.nix
  ];

  systemd.services."systemd-networkd-wait-online".enable = lib.mkForce false;
  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      # From https://nixos.wiki/wiki/Jellyfin
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        vpl-gpu-rt
      ];
    };
  };

  ########################################
  # Secrets
  ########################################
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.cloudflare-tunnel = {};
  sops.secrets.cloudflare = {}; # Cloudflare API token (Zone:DNS:Edit) for ACME DNS-01
  sops.secrets.bigagi = {};
  sops.secrets.kanidm-tls-chain = {
    owner = "kanidm";
    group = "kanidm";
  };
  sops.secrets.kanidm-tls-key = {
    owner = "kanidm";
    group = "kanidm";
  };
  sops.secrets.restic-immich = {};
  sops.secrets.restic-postgresql = {};
  # EnvironmentFile (systemd.exec(5) format) with AWS_ACCESS_KEY_ID,
  # AWS_SECRET_ACCESS_KEY, RESTIC_PASSWORD and RESTIC_REPOSITORY for the
  # offsite immich-remote S3 backup below.
  sops.secrets.restic-remote-immich-env = {};

  # Miniflux admin credentials (feeds into adminCredentialsFile below).
  sops.secrets.miniflux = {};

  # Consumed by modules/paperclip.nix (PAPERCLIP_PUBLIC_URL); value lives in
  # common.yaml.
  sops.secrets.tailnet-domain = {
    sopsFile = ../../common.yaml;
  };

  # Hister kanidm OIDC client secret + tailnet base URL, injected into the
  # service as HISTER__* env vars (which override `settings`) so they never
  # land in the world-readable Nix store (see the Hister section below).
  sops.secrets.hister-oidc-secret = {};
  sops.templates.hister-env = {
    mode = "0400";
    content = ''
      HISTER__SERVER__OAUTH__OIDC__CLIENT_SECRET=${config.sops.placeholder.hister-oidc-secret}
      HISTER__SERVER__BASE_URL=https://hister.${config.sops.placeholder.tailnet-domain}
    '';
  };

  ########################################
  # Nix
  ########################################
  nix.settings = {
    trusted-users = ["root" "@wheel"];
    extra-substituters = [
      # default priority is 40, lower = checked first
      # For pre-built zerotier package
      "https://nix-community.cachix.org?priority=50"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  ########################################
  # Boot
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
  # Allow full REISUB via nanokvm HID injection for out-of-band recovery:
  # R=4 (unraw) + S=16 (sync) + U=32 (remount-ro) + E/I=64 (kill) + B=128 (reboot)
  boot.kernel.sysctl."kernel.sysrq" = 4 + 16 + 32 + 64 + 128;

  powerManagement.enable = true;

  ########################################
  # Networking
  ########################################
  networking = {
    hostName = "r1pro";
    useNetworkd = true;
    # wireless.enable = false;
    networkmanager.enable = false;

    # BBR congestion control + TCP MTU probing
    performance.enable = true;
    #domain = "home.macdermid.ca";
    # TODO: set?
    #hostId = "f5a3f353";
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [443];
    allowedUDPPorts = [
      5353 # mDNS
      5355 # LLMNR (Link-Local Multicast Name Resolution)
    ];
    trustedInterfaces = ["tailscale0"];
    interfaces."tailscale0".allowedTCPPorts = [
      443 # Serve?
    ];
  };

  ########################################
  # ProtonVPN network namespace (qBittorrent)
  ########################################
  # qBittorrent runs inside a dedicated network namespace whose only routes
  # are the WireGuard tunnel (protonvpn0) plus a /30 veth to the host for
  # nginx. Fails closed.

  sops.secrets.protonvpn-wg-key = {
    restartUnits = ["protonvpn.service"];
  };

  # Resolver for the qBittorrent namespace: Proton's DNS is only reachable
  # through the tunnel, so lookups also fail closed when it is down.
  environment.etc."qbittorrent/resolv.conf".text = ''
    nameserver 10.2.0.1
  '';

  systemd.services.protonvpn = {
    description = "ProtonVPN wireguard network namespace for qBittorrent";
    after = ["network.target" "sops-nix.service"];
    before = ["qbittorrent.service"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [
      iproute2
      wireguard-tools
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "protonvpn-start" ''
        set -euo pipefail
        NS=protonvpn
        IFACE=protonvpn0

        # Idempotent, but only when the namespace is fully configured (tunnel
        # + veth present). A partial namespace left by an earlier failed start
        # is torn down and rebuilt instead of being silently reused.
        if [ -e "/run/netns/$NS" ]; then
          if ip -n "$NS" link show "$IFACE" >/dev/null 2>&1 \
            && ip -n "$NS" link show veth-protonvpn0 >/dev/null 2>&1; then
            exit 0
          fi
          ip netns del "$NS"
        fi

        # Namespace with only loopback up.
        ip netns add "$NS"
        ip -n "$NS" link set lo up

        # Create the wireguard interface in the root namespace (its UDP
        # socket must reach the endpoint via the physical uplink), then
        # move it into the namespace; the socket stays in the root ns.
        ip link add "$IFACE" type wireguard
        wg set "$IFACE" private-key ${config.sops.secrets.protonvpn-wg-key.path}
        wg set "$IFACE" peer 9E5iMJSAG7GKxLXJ+AmiE66vfxx41V7aknXCHmvbqlk= \
          endpoint 79.135.104.99:51820 \
          allowed-ips 0.0.0.0/0,::/0 \
          persistent-keepalive 25
        ip link set "$IFACE" netns "$NS"

        # Tunnel addressing. Lower MTU (e.g. 1350) if transfers stall.
        ip -n "$NS" addr add 10.2.0.2/32 dev "$IFACE"
        ip -n "$NS" link set "$IFACE" mtu 1420 up

        # /30 veth to the host: the only non-tunnel route inside the
        # namespace, used by nginx to reach the WebUI.
        ip link add veth-protonvpn type veth peer name veth-protonvpn0 netns "$NS"
        ip addr add 192.168.200.1/30 dev veth-protonvpn
        ip link set veth-protonvpn up
        ip -n "$NS" addr add 192.168.200.2/30 dev veth-protonvpn0
        ip -n "$NS" link set veth-protonvpn0 up

        # The namespace's only default route: straight into the tunnel.
        ip -n "$NS" route add default dev "$IFACE"
      '';
      ExecStop = pkgs.writeShellScript "protonvpn-stop" ''
        set -euo pipefail
        ip link del veth-protonvpn 2>/dev/null || true
        ip netns del protonvpn 2>/dev/null || true
      '';
    };
  };

  # Run qBittorrent inside the namespace. The filesystem stays shared, so
  # the module's profile paths keep working unchanged.
  systemd.services.qbittorrent = {
    bindsTo = ["protonvpn.service"];
    after = ["protonvpn.service"];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/protonvpn";
      # A user namespace would prevent joining the root-owned network
      # namespace; every other sandbox option from the module still applies.
      PrivateUsers = lib.mkForce false;
      # No systemd-resolved stub inside the namespace; point glibc at
      # Proton's resolver via the tunnel instead.
      TemporaryFileSystem = ["/etc/resolv.conf"];
      BindReadOnlyPaths = ["/etc/qbittorrent/resolv.conf:/etc/resolv.conf"];
    };
  };

  # NAT-PMP: lease a forwarded port from Proton's gateway and keep
  # qBittorrent's listening port synced to it so inbound peers work. Runs
  # inside the namespace: natpmpc reaches 10.2.0.1 through the tunnel and
  # the WebUI API call stays on the /30 veth (auth-bypassed via
  # WebUI\AuthSubnetWhitelist). Proton grants a short lease, so the loop
  # renews every 45s; on failure it retries without touching the port.
  systemd.services.protonvpn-portfwd = {
    description = "ProtonVPN NAT-PMP port lease for qBittorrent";
    bindsTo = ["protonvpn.service"];
    partOf = ["qbittorrent.service"];
    after = ["protonvpn.service" "qbittorrent.service"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [
      curl
      gawk
      libnatpmp
    ];
    serviceConfig = {
      Type = "simple";
      NetworkNamespacePath = "/run/netns/protonvpn";
      Restart = "on-failure";
      RestartSec = "15s";
      NoNewPrivileges = true;
      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      ExecStart = pkgs.writeShellScript "protonvpn-portfwd" ''
        set -euo pipefail
        GW=10.2.0.1
        WEBUI=http://192.168.200.2:59933
        last=""

        while true; do
          port=""
          if port=$(natpmpc -a 1 0 udp 120 -g "$GW" \
                    | awk '/Mapped public port/ {print $4; exit}') \
            && [ -n "$port" ] \
            && natpmpc -a 1 0 tcp 120 -g "$GW" >/dev/null; then
            if [ "$port" != "$last" ]; then
              echo "protonvpn: forwarded port $port"
              if curl -fsS -o /dev/null \
                --data-urlencode "json={\"listen_port\":$port}" \
                "$WEBUI/api/v2/app/setPreferences"; then
                last="$port"
              else
                echo "protonvpn: could not update qBittorrent; will retry" >&2
              fi
            fi
          else
            echo "protonvpn: NAT-PMP renewal failed; retrying" >&2
          fi
          sleep 45
        done
      '';
    };
  };

  ########################################
  # Services
  ########################################
  # Rebuild from the flake source captured at deploy time (self.outPath)
  system.autoUpgrade = {
    enable = false;
    flake = self.outPath;
    flags = [
      "--recreate-lock-file"
      "-L" # print build logs
    ];
    dates = "03:30";
    randomizedDelaySec = "45min";
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "r1pro" = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
        default = "http_status:404";
      };
    };
  };
  systemd.services.cloudflared-tunnel-r1pro = {
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      RestartSec = "30s";
    };
  };
  services.fwupd.enable = true;
  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };
  systemd.services.jellyfin = {
    environment = {
      JELLYFIN_PublishedServerUrl = "https://jellyfin.home.macdermid.ca";
    };
    serviceConfig = {
      CapabilityBoundingSet = "";
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectHome = true;
      # TODO: review 'true' in module ProtectSystem = "strict";
      ProtectClock = true;
      ReadWritePaths = [
        "/srv/media"
        config.services.jellyfin.dataDir
        config.services.jellyfin.configDir
        config.services.jellyfin.cacheDir
        config.services.jellyfin.logDir
      ];
    };
  };
  services.kanidm = {
    # Before upgrade test: sudo -u kanidm -g kanidm kanidmd domain upgrade-check
    package = pkgs.kanidm_1_11;
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
        http_client_address_info.x-forward-for = ["127.0.0.1"];
      };
    };
    client = {
      enable = true;
      settings = {
        uri = "${config.services.kanidm.server.settings.origin}";
      };
    };
  };

  ########################################
  # Matrix homeserver (tuwunel) for agent chat. Public ingress: r1pro's
  # cloudflared tunnel, remote-managed in the Cloudflare dashboard
  # (matrix.macdermid.ca -> HTTP -> localhost:6167). Not behind Cloudflare
  # Access: clients authenticate with Bearer tokens, not browser SSO — the
  # registration token is the access-control layer. Agent-only: federation
  # off (never open 8448), E2EE off so plain HTTP client libraries work.
  ########################################
  services.matrix-tuwunel = {
    enable = true;
    settings.global = {
      address = ["127.0.0.1"];
      port = [6167];
      server_name = "matrix.macdermid.ca";
      allow_federation = false;
      allow_encryption = false;
      # Required for token-gated registration; false closes it entirely.
      allow_registration = true;
      registration_token_file = config.sops.secrets.matrix-registration-token.path;
      # Stay under Cloudflare's 100 MB free-tier upload cap.
      max_request_size = 50 * 1024 * 1024;
      # Exact-match CORS allowlist; only browser clients preflight. Add a
      # new web client here or its requests fail with no ACAO header.
      access_control_allow_origin = [
        "vector://vector" # Element Desktop
        "https://app.element.io" # Element Web
      ];
      # tuwunel enables RocksDB O_DIRECT by default, but bcachefs only allows
      # 4K-aligned DIO, so RocksDB's 512B SST pwrites fail with EINVAL
      # (cf. upstream tuwunel#195). Buffered I/O costs page-cache RAM — fine
      # at this scale.
      rocksdb_direct_io = false;
    };
  };
  sops.secrets.matrix-registration-token = {
    owner = "tuwunel";
    group = "tuwunel";
    restartUnits = ["tuwunel.service"];
  };
  # Defense-in-depth on top of the module's sandbox. The matrix.org egress
  # exception is required: Element X registers its HTTP pusher there, and
  # denying it silently kills background notifications. Relax if an
  # appservice or federation is ever enabled.
  systemd.services.tuwunel.serviceConfig = {
    CapabilityBoundingSet = "";
    IPAddressAllow = ["localhost" "matrix.org"];
    IPAddressDeny = ["any"];
    UMask = "0077";
  };

  services.nordvpn-namespaced = {
    enable = true;
    namespaces = {
      romania = {
        remote = "89.46.103.171";
        verify-x509-name = "ro67.nordvpn.com";
      };
    };
  };
  services.nzbget.enable = true;
  systemd.services.nzbget.serviceConfig = {
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictAddressFamilies = ["AF_INET"]; # "AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX"];
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    ProtectClock = true;
    ProtectHostname = true;
    RemoveIPC = true;
    #    ProtectProc = "invisible";
    #    ProcSubset = "pid";

    PrivateTmp = true;
    PrivateDevices = true;
    CapabilityBoundingSet = [""];
    #    ProtectHome = true;

    #    ProtectSystem = "strict"; issues: reads /proc cpuinfo
    #    ReadWritePaths = [ "/mnt/media/" ];

    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
    ];
  };
  systemd.services.nzbget.path = with pkgs; [
    unrar
    uv
    p7zip
    (python3.withPackages (python-pkgs: [
      local.pynzbget
      python-pkgs.apprise
    ]))
  ];
  services.mongodb = {
    enable = true;
    package = local.mongodb-bin_7;
    # Oddly the auth/initialRootPassword didn't work
    pidFile = "/run/mongodb/mongodb.pid";
    extraConfig = ''
      net:
        unixDomainSocket:
          enabled: true
          filePermissions: 0777
          pathPrefix: "/run/mongodb"

      security.authorization: enabled
      setParameter:
        authenticationMechanisms: SCRAM-SHA-256
    '';
  };
  systemd.services.mongodb.serviceConfig = {
    RuntimeDirectory = "mongodb";

    # https://www.mongodb.com/docs/manual/reference/ulimit
    LimitFSIZE = "infinity";
    LimitCPU = "infinity";
    LimitAS = "infinity";
    LimitMEMLOCK = "infinity";
    LimitNOFILE = 64000;
    LimitNPROC = 64000;
  };
  services.openssh = {
    enable = true;
    openFirewall = true;
    extraConfig = ''
      PrintLastLog no

      Match User media
        ChrootDirectory /srv/media

        AllowAgentForwarding no
        AllowTcpForwarding no
        X11Forwarding no

        ForceCommand internal-sftp
    '';
    settings.PasswordAuthentication = true;
  };
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    # Vector Extension
    extensions = ps:
      with ps; [
        pgvector
        vectorchord
      ];
    settings.shared_preload_libraries = [
      "vchord"
      "vector"
    ];
    # CREATE EXTENSION IF NOT EXISTS vector;
    # CREATE EXTENSION IF NOT EXISTS vchord;

    authentication = ''
      local all all ident map=mapping
    '';
    identMap = ''
      mapping kenny    postgres
      mapping root     postgres
      mapping postgres postgres
      mapping /^(.*)$  \1
    '';
  };

  ########################################
  # Immich
  ########################################
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    mediaLocation = "/srv/immich";
    accelerationDevices = ["/dev/dri/renderD128"];

    machine-learning.enable = true;
  };
  # Pin immich to uid/gid 911 (consistent with yoga) and grant GPU access.
  users.users.immich = {
    uid = config.ids.uids.immich;
    extraGroups = ["render" "video"];
  };
  users.groups.immich.gid = config.ids.gids.immich;

  # Expose Immich privately on the tailnet over HTTPS, mirroring r1pro's other
  # tailscale-serve-* services.
  systemd.services.tailscale-serve-immich = {
    description = "Tailscale serve Immich";
    wantedBy = ["multi-user.target"];
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    serviceConfig = {
      RestartSec = 10;
      Restart = "on-failure";
      ExecStartPre = "${lib.getExe waitTailscale}";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --service=svc:immich --https=443 127.0.0.1:2283";
    };
  };
  # Paperclip (podman container from modules/paperclip.nix, bound to
  # 127.0.0.1:3100), served on the tailnet via tailscale serve.
  systemd.services.tailscale-serve-paperclip = {
    description = "Tailscale serve Paperclip";
    wantedBy = ["multi-user.target"];
    after = ["tailscaled.service" "podman-paperclip.service"];
    wants = ["tailscaled.service"];
    serviceConfig = {
      RestartSec = 10;
      Restart = "on-failure";
      ExecStartPre = "${lib.getExe waitTailscale}";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --service=svc:paperclip --https=443 127.0.0.1:3100";
    };
  };

  ########################################
  # Hister (self-hosted web-history search, https://github.com/asciimoo/hister)
  ########################################
  # Multi-user instance behind kanidm OIDC, exposed on the tailnet via
  # tailscale serve (host domain from the tailnet-domain sops secret)
  services.hister = {
    enable = true;

    port = 3004;
    environmentFile = config.sops.templates.hister-env.path;
    settings = {
      app = {
        user_handling = true;
        # log_level = "debug";
      };
      server = {
        # base_url comes from the hister-env sops template as
        # HISTER__SERVER__BASE_URL (env overrides settings, viper precedence)
        oauth_only = true; # Disable password logins
        oauth.oidc = {
          client_id = "hister";
          configuration_url = "https://auth.macdermid.ca/oauth2/openid/hister/.well-known/openid-configuration";
        };
      };
    };
  };

  # TODO: cover /var/lib/hister (sqlite db + indexes) with a restic backup like
  # immich/postgresql above.
  systemd.services.tailscale-serve-hister = {
    description = "Tailscale serve Hister";
    wantedBy = ["multi-user.target"];
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    serviceConfig = {
      RestartSec = 10;
      Restart = "on-failure";
      ExecStartPre = "${lib.getExe waitTailscale}";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --service=svc:hister --https=443 127.0.0.1:3004";
    };
  };

  ########################################
  # Miniflux (feed reader behind kanidm OIDC)
  ########################################
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      DEBUG = "off";
      LISTEN_ADDR = "127.0.0.1:35001";
      BASE_URL = "https://miniflux.macdermid.ca";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://miniflux.macdermid.ca/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.macdermid.ca/oauth2/openid/miniflux";
      OAUTH2_USER_CREATION = "1";
    };
  };

  ########################################
  # Navidrome (self-hosted music streaming)
  ########################################
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/media/music";
    };
  };

  ########################################
  # nginx reverse proxy (LAN-only) for *.home.macdermid.ca
  ########################################
  systemd.services.nginx.serviceConfig.SupplementaryGroups = ["acme"];
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "kenny@macdermid.ca";
      dnsProvider = "cloudflare";
      credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare.path;
      dnsResolver = "1.1.1.1:53";
    };
    certs."home.macdermid.ca" = {
      domain = "*.home.macdermid.ca";
      extraDomainNames = ["home.macdermid.ca"];
      reloadServices = ["nginx"];
    };
  };
  services.nginx = {
    enable = true;
    serverTokens = false;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    sslProtocols = "TLSv1.3";
    clientMaxBodySize = "10g"; # immich video uploads
    commonHttpConfig = ''
      geo $internal {
        default no;
        127.0.0.0/8 yes;
        172.27.0.0/24 yes; # LAN
        100.64.0.0/10 yes; # Tailscale CGNAT
        10.88.0.0/16 yes;  # podman
      }
    '';
    virtualHosts = let
      # LAN-only TLS vhost behind the *.home.macdermid.ca wildcard cert, gated by
      # the `internal` geo-map (404 to anyone off the LAN/tailnet). Add a service
      # with:  "<svc>.home.macdermid.ca" = proxywss <port>;
      # Backend may be a local address other than loopback, e.g. the
      # protonvpn netns veth for qBittorrent (192.168.200.2).
      proxywssAddr = addr: port: {
        onlySSL = true;
        useACMEHost = "home.macdermid.ca";
        http2 = true;
        extraConfig = ''
          if ($internal != yes) {
            return 404;
          }
        '';
        locations."/" = {
          proxyPass = "http://${addr}:${toString port}";
          proxyWebsockets = true;
        };
      };
      proxywss = proxywssAddr "127.0.0.1";
      # Same as proxywss but for an https backend (e.g. UniFi on :8443 with a
      # self-signed cert; nginx trusts the upstream since proxy_ssl_verify is off).
      proxytls = port: {
        onlySSL = true;
        useACMEHost = "home.macdermid.ca";
        http2 = true;
        extraConfig = ''
          if ($internal != yes) {
            return 404;
          }
        '';
        locations."/" = {
          proxyPass = "https://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };
    in {
      "jellyfin.home.macdermid.ca" = proxywss 8096;
      "nzbget.home.macdermid.ca" = proxywss 6789;
      "qbittorrent.home.macdermid.ca" = proxywssAddr "192.168.200.2" 59933;
    };
  };

  ################################################################
  # Backups (restic -> /mnt/red USB drive + S3 offsite)
  ################################################################
  # Dump every postgres DB (immich, miniflux, kanidm, ...) to
  # /var/backup/postgresql/<db>.sql.gz nightly at 01:00 (module default; one
  # file per DB, overwritten each run -- restic snapshots provide history).
  services.postgresqlBackup.enable = true;

  # Immich media: originals + encoded-video + thumbs + profiles, all of /srv/immich.
  # Runs as root so it can read the 0700 immich-owned tree and write to /mnt/red.
  services.restic.backups.immich = {
    initialize = false;
    repository = "/mnt/red/immich-restic";
    passwordFile = config.sops.secrets.restic-immich.path;
    paths = ["/srv/immich"];
    # Going to put the backups on their own subvolume and snapshot so manually
    # prune when required.
    # pruneOpts = [
    #   "--keep-daily 7"
    #   "--keep-weekly 5"
    #   "--keep-monthly 12"
    #   "--keep-yearly 10"
    # ];
    timerConfig = {
      OnCalendar = "04:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  # Postgres dumps from services.postgresqlBackup (covers the immich DB + all
  # others). Runs after the 01:00 dump completes.
  services.restic.backups.postgresql = {
    initialize = false;
    repository = "/mnt/red/restic-postgresql";
    passwordFile = config.sops.secrets.restic-postgresql.path;
    paths = ["/var/backup/postgresql"];
    # pruneOpts = [
    #   "--keep-daily 7"
    #   "--keep-weekly 5"
    #   "--keep-monthly 12"
    #   "--keep-yearly 10"
    # ];
    timerConfig = {
      OnCalendar = "03:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  # Offsite weekly copy to S3 (DEEP_ARCHIVE); repository, credentials and
  # password all come from the restic-remote-immich-env secret, so
  # `repository` is intentionally unset. Excludes thumbs/ and encoded-video/
  # (covered by the local /mnt/red backup) and immich's backups/ staging.
  services.restic.backups.immich-remote = {
    initialize = false;
    environmentFile = config.sops.secrets.restic-remote-immich-env.path;
    paths = ["/srv/immich"];
    exclude = [
      "/srv/immich/thumbs"
      "/srv/immich/encoded-video"
      "/srv/immich/backups"
    ];
    extraBackupArgs = [
      "--tag=immich"
      "--limit-upload=400"
    ];
    extraOptions = ["s3.storage-class=DEEP_ARCHIVE"];
    timerConfig = {
      OnCalendar = "Sun 02:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  services.qbittorrent = {
    # Runs inside the protonvpn network namespace (see the ProtonVPN section
    # above); all torrent traffic + DNS goes through the tunnel or fails.
    enable = true;
    group = "media";
    webuiPort = 59933;
  };
  # The NixOS qbittorrent module hardcodes a 30min shutdown timeout
  # (TimeoutStopSec=1800), which stalls reboots when the client lingers on
  # shutdown. Cap it instead. mkForce is required because the module sets
  # the value at default priority.
  systemd.services.qbittorrent.serviceConfig.TimeoutStopSec = lib.mkForce "30s";
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "${config.networking.hostName}";
        "netbios name" = "${config.networking.hostName}";
        "security" = "user";
        "hosts allow" = "192.168.2. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      media = {
        path = "/srv/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "guest only" = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = config.users.users.media.name;
        "force group" = config.users.groups.media.name;
      };
    };
  };
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.bigagi = {
    image = "localhost/bigagi:stable";
    environmentFiles = [config.sops.secrets.bigagi.path];
    ports = ["127.0.0.1:3000:3000"];
  };
  virtualisation.oci-containers.containers.agent-zero = {
    image = "docker.io/agent0ai/agent-zero:v2.14";
    # ports = ["127.0.0.1:902:80"];
    volumes = [
      "agent-zero-data:/a0/usr"
      # One-file patch: memory consolidation timeout 60s -> 300s. Consolidation
      # silently DROPS the memory when it exceeds the timeout (upstream issue
      # #1416; the 300s fix PR #1469 was closed unmerged), so slow utility
      # models lose memories. Patched against image tag v2.13 — when bumping
      # the image version, re-diff hosts/r1pro/agent-zero/
      # memory_consolidation.py against the new tag and regenerate if needed
      # (see its header comment).
      "${./agent-zero/memory_consolidation.py}:/a0/plugins/_memory/helpers/memory_consolidation.py:ro"
    ];
    extraOptions = [
      # Static IP for tailscale forwarding
      "--ip=10.88.0.10"
    ];
  };
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      dns_enabled = true;
      # Use /24 with 100-200 for dynamic
      subnets = [
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
  zramSwap.enable = true;

  ########################################
  # User
  ########################################
  users.motd = ''
    Welcome to r1pro. This system is running NixOS.

    To find a package:
    $ nix search nixpkgs ___
    or use https://search.nixos.org/packages

    To install a package:
    $ nix shell nixpkgs#___
  '';

  users.groups.media.members = with config.users.users; [
    config.services.jellyfin.user
    config.services.nzbget.user

    kenny.name
    media.name
  ];

  users.users.media = {
    uid = config.ids.uids.media;
    home = "/srv/media";
    homeMode = "2770";
    isNormalUser = true;
    shell = pkgs.shadow;
    group = "media";
  };

  users.users.sftp-yoga = {
    uid = config.ids.uids.sftp-yoga;
    sftpOnly = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJ0iluA6vWgJ0cBfwLLYLozRJ4r7UBxkPYzOWWqYcf/"
    ];
  };

  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };

  # Passwordless sudo for the wheel group (kenny) so the pi SSH agent can run
  # privileged diagnostics (e.g. reading PCI config space for ASPM state)
  # without an interactive password.
  security.sudo.wheelNeedsPassword = false;

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    alejandra
    bcachefs-tools
    btrfs-progs
    dhcpcd
    git
    gitui
    gnumake
    fd
    fwupd
    htop
    kitty # for term info only
    libva-utils
    mongosh
    ncdu
    powertop
    pstree
    restic
    ripgrep
    tmux
    wireguard-tools
  ];
}
