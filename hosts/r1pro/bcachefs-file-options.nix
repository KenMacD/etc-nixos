# Set data_replicas=1 on large recreatable trees (fs default is 2) to halve
# their disk footprint. Check on every activation to handle if they're recreated
# (can't set on disko, afaik) and to avoid applying if not needed.
{pkgs, ...}: let
  bcachefs = "${pkgs.bcachefs-tools}/bin/bcachefs";
  getfattr = "${pkgs.attr}/bin/getfattr";
in {
  system.activationScripts.bcachefsFileOpts = ''
    for d in /srv/media /var/tmp /home/kenny/.cache /home/kenny/tmp /var/cache; do
      if [ -d "$d" ]; then
        cur="$(${getfattr} --only-values -n bcachefs.data_replicas "$d" 2>/dev/null || true)"
        if [ "$cur" != "1" ]; then
          ${bcachefs} set-file-option --data_replicas=1 "$d" \
            || echo "warning: failed to set data_replicas=1 on $d" >&2
        fi
      fi
    done
  '';
}
