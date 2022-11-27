{ config, lib, pkgs, ... }: {

  boot.postBootCommands = ''
    echo "always" > /sys/kernel/mm/transparent_hugepage/enabled
    echo "defer+madvise" > /sys/kernel/mm/transparent_hugepage/defrag
  '';
  boot.kernelParams = [
    # "intel_iommu=on"
  ];

  users.users.kenny.extraGroups = [
    "kvm"
    "libvirtd"
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
    podman-tui

    # Testing gvisor runtime
    gvisor

    # Testing firecracker
    firecracker
    firectl
    ignite
    # firecracker-containerd (doesn't exist)

    # Kubernetes stuff
    k9s
    kind
    krew  # kubectl plugin manager
    kubectl
    kubecolor  # kubectl with color output
    kubernetes-helm

    # Kubenetes testing:
    kubectx  # kubectx & kubens
    kubeswitch
    stern  # multi-pod tail
    minikube
  ];
}
