{
  self,
  config,
  lib,
  pkgs,
  system,
  ...
}: {
  # To use run `mitmproxy --set confdir=/etc/mitmproxy`;
  # or in `~/.mitmproxy.conf set `confdir: /etc/mitmproxy`

  # Create /etc/mitmproxy config directory
  sops.secrets.mitmproxy-ca-pem = {
    owner = "kenny";
    path = "/etc/mitmproxy/mitmproxy-ca.pem";
  };
  environment.etc."mitmproxy/mitmproxy-dhparam.pem".source = ./mitmproxy-dhparam.pem;

  # Add mitmproxy as a trusted certificate
  security.pki.certificateFiles = [
    ./mitmproxy-ca-cert.pem
  ];
}
