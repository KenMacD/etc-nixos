{ stdenv
, lib
, fetchFromGitHub
, cmake
, docbook-xsl-nons
, libxslt
, pkg-config
, alsa-lib
, faac
, faad2
, ffmpeg
, glib
, openh264
, openssl
, pcre2
, zlib
, libX11
, libXcursor
, libXdamage
, libXdmcp
, libXext
, libXi
, libXinerama
, libXrandr
, libXrender
, libXtst
, libXv
, libxkbcommon
, libxkbfile
, wayland
, gstreamer
, gst-plugins-base
, gst-plugins-good
, libunwind
, orc
, cairo
, libusb1
, libpulseaudio
, cups
, pcsclite
, systemd
, libjpeg_turbo
, icu
, SDL2
, SDL2_ttf
, krb5
, cjson
, pkcs11helper
, webkitgtk
, buildServer ? true
, nocaps ? false
, AudioToolbox
, AVFoundation
, Carbon
, Cocoa
, CoreMedia
, fuse3
, withUnfree ? false

# QT
, wrapQtAppsHook
, qtwebengine
}:

# Import, modified from: https://github.com/nix-community/nixpkgs-wayland/blob/e2939a783e2973968f3eddbcc00a79bdffc63aa2/pkgs/freerdp3/default.nix
# Move metadata in to this file
# Added QT settings
# NB: add gnome.glib-networking
# NB: call with:
#    freerdp3 = libsForQt5.callPackage ./freerdp3.nix {
#      inherit (darwin.apple_sdk.frameworks) AudioToolbox AVFoundation Carbon Cocoa CoreMedia;
#      inherit (gst_all_1) gstreamer gst-plugins-base gst-plugins-good;
#    };

let
  version = "3.2.0";
  sha256 = "sha256-fpoiIfgT+dOQcTKtxS2EuAuvbEb+UA/hnqxUHuvbFwA=";

  cmFlag = flag: if flag then "ON" else "OFF";
  disabledTests = lib.optionals stdenv.isDarwin [
    {
      dir = "winpr/libwinpr/sysinfo/test";
      file = "TestGetComputerName.c";
    }
  ];

  inherit (lib) optionals;

in
stdenv.mkDerivation rec {
  pname = "freerdp";
  inherit version;

  src = fetchFromGitHub {
    owner = "FreeRDP";
    repo = "FreeRDP";
    rev = version;
    inherit sha256;
  };

  postPatch = ''
    export HOME=$TMP

    # skip NIB file generation on darwin
    sed -z 's/NIB file generation.*//' -i client/Mac{,/cli}/CMakeLists.txt

    # failing test(s)
    ${lib.concatMapStringsSep "\n" (e: ''
      substituteInPlace ${e.dir}/CMakeLists.txt \
        --replace ${e.file} ""
      rm ${e.dir}/${e.file}
    '') disabledTests}

    substituteInPlace "libfreerdp/freerdp.pc.in" \
      --replace "Requires:" "Requires: @WINPR_PKG_CONFIG_FILENAME@"
  '' + lib.optionalString (pcsclite != null) ''
    substituteInPlace "winpr/libwinpr/smartcard/smartcard_pcsc.c" \
      --replace "libpcsclite.so" "${lib.getLib pcsclite}/lib/libpcsclite.so"
  '' + lib.optionalString nocaps ''
    substituteInPlace "libfreerdp/locale/keyboard_xkbfile.c" \
      --replace "RDP_SCANCODE_CAPSLOCK" "RDP_SCANCODE_LCONTROL"
  '';

  buildInputs = [
    cairo
    cups
    faad2
    ffmpeg
    fuse3
    glib
    gst-plugins-base
    gst-plugins-good
    gstreamer
    icu
    libX11
    libXcursor
    libXdamage
    libXdmcp
    libXext
    libXi
    libXinerama
    libXrandr
    libXrender
    libXtst
    libXv
    libjpeg_turbo
    libpulseaudio
    libunwind
    libusb1
    libxkbcommon
    libxkbfile
    openh264
    openssl
    orc
    pcre2
    pcsclite
    zlib
    SDL2
    SDL2_ttf
    krb5
    cjson
    pkcs11helper
    webkitgtk

    qtwebengine

  ] ++ optionals stdenv.isLinux [
    alsa-lib
    systemd
    wayland
  ] ++ optionals stdenv.isDarwin [
    AudioToolbox
    AVFoundation
    Carbon
    Cocoa
    CoreMedia
  ]
  ++ optionals withUnfree [
    faac
  ];

  nativeBuildInputs = [ cmake libxslt docbook-xsl-nons pkg-config wrapQtAppsHook];

  doCheck = true;

  # https://github.com/FreeRDP/FreeRDP/issues/8526#issuecomment-1357134746
  cmakeFlags = [
    "-Wno-dev"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DDOCBOOKXSL_DIR=${docbook-xsl-nons}/xml/xsl/docbook"
  ]
  ++ lib.mapAttrsToList (k: v: "-D${k}=${cmFlag v}") {
    BUILD_TESTING = false; # false is recommended by upstream
    WITH_CAIRO = cairo != null;
    WITH_CUPS = cups != null;
    WITH_FAAC = withUnfree && faac != null;
    WITH_FAAD2 = faad2 != null;
    WITH_JPEG = libjpeg_turbo != null;
    WITH_OPENH264 = openh264 != null;
    WITH_OSS = false;
    WITH_PCSC = pcsclite != null;
    WITH_PULSE = libpulseaudio != null;
    WITH_SERVER = buildServer;
    WITH_VAAPI = false; # false is recommended by upstream
    WITH_X11 = true;
    WITH_WEBVIEW_QT = true;
  };

  env = {
    NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isDarwin
      "-DTARGET_OS_IPHONE=0 -DTARGET_OS_WATCH=0 -include AudioToolbox/AudioToolbox.h";

    NIX_LDFLAGS = lib.optionalString stdenv.isDarwin
      "-framework AudioToolbox";
  };

  meta = with lib; {
    description = "A Remote Desktop Protocol Client";
    longDescription = ''
      FreeRDP is a client-side implementation of the Remote Desktop Protocol (RDP)
      following the Microsoft Open Specifications.
    '';
    homepage = "https://www.freerdp.com/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
