{ config, lib, pkgs, ... }: {

  boot.postBootCommands = ''
    echo "always" > /sys/kernel/mm/transparent_hugepage/enabled
    echo "defer+madvise" > /sys/kernel/mm/transparent_hugepage/defrag
  '';
  boot.kernelParams = [
    # "intel_iommu=on"
  ];

  ########################################
  # Containers
  ########################################
  virtualisation = {
    # docker = {
    #   enable = true;
    #   storageDriver = "overlay2";
    # };
    kvmgt.enable = true;
    libvirtd = {
      enable = true;
      qemu.ovmf.package = pkgs.OVMFFull;
    };
    # Also user USB redirection... for now.
    spiceUSBRedirection.enable = true;
    lxc = {
      enable = true;
      lxcfs.enable = true;
    };
    podman = {
      enable = true;
      dockerCompat = true;
    };
    lxd.enable = true;
    waydroid.enable = true;
    # virtualbox.host.enable = true;
  };
}
