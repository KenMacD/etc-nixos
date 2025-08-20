{
  stdenv,
  python3,
  openvpn,
  iproute2,
  util-linux,
  fetchFromGitHub,
}:
# From: https://github.com/bakhtiyarneyman/nixos-configs/blob/6cf5413488a80d229fab6aa2719eaa2bf32f053b/pkgs/namespaced-openvpn.nix
# See (for setup): https://github.com/bakhtiyarneyman/nixos-configs/blob/6cf5413488a80d229fab6aa2719eaa2bf32f053b/modules/namespaced-openvpn.nix
# Also see other forks for updates
stdenv.mkDerivation rec {
  name = "namespaced-openvpn";

  src = fetchFromGitHub {
    owner = "slingamn";
    repo = name;
    rev = "master";
    sha256 = "190604sd6djmzfkymgqf60zj0bydbi97klphyy3m3j06s71mlmzq";
  };

  patchPhase = ''
    substituteInPlace ${name} \
      --replace "/usr/sbin/openvpn" "${openvpn}/bin/openvpn" \
      --replace "/sbin/ip" "${iproute2}/bin/ip" \
      --replace "/usr/bin/nsenter" "${util-linux}/bin/nsenter" \
      --replace "/bin/mount" "${util-linux}/bin/mount" \
      --replace "/bin/umount" "${util-linux}/bin/umount"
  '';

  buildInputs = [python3 openvpn];
  buildPhase = "echo 'Do nothing'";

  installPhase = ''
    mkdir -p $out/bin
    cp --recursive ${name} $out/bin
    runHook postInstall
  '';

  checkPhase = "make test";
}
