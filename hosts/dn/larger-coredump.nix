{ config, lib, pkgs, ... }: {

  # Unfortunately it's not possible to update 1 value
  systemd.coredump.extraConfig = ''
    #Storage=external
    #Compress=yes
    #ProcessSizeMax=2G
    ProcessSizeMax=10G
    #ExternalSizeMax=2G
    ExternalSizeMax=10G
    #JournalSizeMax=767M
    #MaxUse=
    #KeepFree=
  '';
}
