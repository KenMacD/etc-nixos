{
  config,
  lib,
  pkgs,
  ...
}: let
  XDG_BIN_HOME = "$HOME/.local/bin";
  XDG_DATA_HOME = "$HOME/.local/share";
  XDG_CONFIG_HOME = "$HOME/.config";
  XDG_CACHE_HOME = "$HOME/.cache";
  XDG_STATE_HOME = "$HOME/.local/state";
in {
  # Made xdg-ninja happier
  # Not sure if here makes sense, :shrug:
  environment.variables = {
    XDG_BIN_HOME = "${XDG_BIN_HOME}";
    XDG_DATA_HOME = "${XDG_DATA_HOME}";
    XDG_CONFIG_HOME = "${XDG_CONFIG_HOME}";
    XDG_CACHE_HOME = "${XDG_CACHE_HOME}";
    XDG_STATE_HOME = "${XDG_STATE_HOME}";

    ANDROID_HOME = "${XDG_DATA_HOME}/android";

    CARGO_HOME = "${XDG_DATA_HOME}/cargo";

    # Fix curl & httpie tls verification
    CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";

    DOCKER_CONFIG = "${XDG_CONFIG_HOME}/docker";

    # Doesn't work with services
    # GNUPGHOME = "${XDG_DATA_HOME}/gnupg";

    GOPATH = "${XDG_DATA_HOME}/go";

    GRADLE_USER_HOME = "${XDG_DATA_HOME}/gradle";

    MINIKUBE_HOME = "${XDG_DATA_HOME}/minikube";

    TERMINFO = "${XDG_DATA_HOME}/terminfo";
    TERMINFO_DIRS = "${XDG_DATA_HOME}/terminfo:/usr/share/terminfo";

    PASSWORD_STORE_DIR = "${XDG_DATA_HOME}/pass";
  };

  environment.systemPackages = with pkgs; [
    xdg-ninja
  ];
}
