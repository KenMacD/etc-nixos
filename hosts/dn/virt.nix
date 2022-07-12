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
    kvmgt.enable = true;
    libvirtd = {
      enable = true;
      # Only care about host arch:
      qemu.package = pkgs.qemu_kvm;
    };

    # Add when user USB redirection retuired:
    # spiceUSBRedirection.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.dnsname.enable = true;
    };

    waydroid.enable = true;
  };

  # kind on rootless podman requires:
  systemd.enableUnifiedCgroupHierarchy = true;
  systemd.services."user@".serviceConfig = { Delegate = "yes"; };

  environment.systemPackages = with pkgs; [
    podman-compose

    # Kubernetes stuff
    kubectl
    kind
    kubernetes-helm
  ];
}
