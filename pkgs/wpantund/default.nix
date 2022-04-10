{ lib, stdenv, fetchFromGitHub, gcc, gettext, boost, dbus, readline, autoconf
, autoconf-archive, automake, autoreconfHook, libtool, pkg-config }:

stdenv.mkDerivation rec {
  pname = "wpantund";
  version = "25dd5d02dedc5e13f28b6fa72674f3486fa0e404";

  src = fetchFromGitHub {
    owner = "openthread";
    repo = "wpantund";
    rev = version;
    sha256 = "sha256-am+qean89Y79CO/XNBo+8eQ/2xaCk2tO76iOnqhQ5Wg=";
  };

  buildInputs = [ dbus readline boost ];

  nativeBuildInputs = [
    autoreconfHook
    gettext
    gcc
    autoconf
    autoconf-archive
    automake
    libtool
    pkg-config
  ];

  meta = with lib; {
    description = "A Wireless Network Interface Daemon for Low-Power Wireless SoCs";
    homepage = "https://github.com/openthread/wpantund";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
