{
  lib,
  pkgs,
  config,
  ...
} @ inputs: {
  # https://github.com/shiryel/nixos-dotfiles/blob/3244dd4933430a8f2c3077b68d5b5c6631805626/system/modules/bwrap.nix

  environment.systemPackages = with pkgs; [
    bubblewrap

    # GENERIC WRAPPER
    (pkgs.writeScriptBin "wrap" ''
      #!${pkgs.stdenv.shell}
      mkdir -p ~/bwrap/generic_wrap
      exec ${lib.getBin pkgs.bubblewrap}/bin/bwrap \
        --ro-bind /run /run \
        --ro-bind /bin /bin \
        --ro-bind /etc /etc \
        --ro-bind /nix /nix \
        --ro-bind /sys /sys \
        --ro-bind /var /var \
        --dev /dev \
        --proc /proc \
        --tmpfs /tmp \
        --tmpfs /home \
        --unshare-user-try --unshare-pid --unshare-uts --unshare-cgroup-try \
        --new-session \
        --dev-bind /dev /dev \
        --bind-try ~/bwrap/generic_wrap ~/ \
        $@
    '')
  ];
}
