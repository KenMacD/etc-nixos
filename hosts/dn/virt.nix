{
  config,
  lib,
  pkgs,
  ...
}: {
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
    "lxd"
  ];

  ########################################
  # Containers
  ########################################
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.ovmf = {
        enable = true;
      };
      # Only care about host arch:
      qemu.package = pkgs.qemu_kvm;
    };

    # Add when user USB redirection retuired:
    # spiceUSBRedirection.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # If lxd is removed then the values from the modules sysctl should
    # probably be copied to avoid issues like kind-in-podman from running
    # out of files.
    lxd.enable = true;
    lxd.recommendedSysctlSettings = true;

    waydroid.enable = true;

    appvm = {
      enable = true;
      user = "kenny";
    };
  };

  # kind on rootless podman requires:
  # Need to force this because lxd disables it
  systemd.enableUnifiedCgroupHierarchy = lib.mkForce true;
  systemd.services."user@".serviceConfig = {Delegate = "yes";};

  security.pam.loginLimits = [
    # Raised to test yugabyte db in kind
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }

    # Podman seems to want more processes to start?
    # crun: setrlimit `RLIMIT_NPROC`: Operation not permitted: OCI permission denied
    {
      domain = "*";
      type = "hard";
      item = "nproc";
      value = "1048576";
    }
  ];

  environment.systemPackages = with pkgs; [
    buildah
    distrobox
    podman-compose
    podman-tui
    cri-tools

    dive # A tool for exploring a docker image

    trivy # vuln scanner

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
    krew # kubectl plugin manager
    kubectl
    kubecolor # kubectl with color output
    kubernetes # kubeadm
    kubernetes-helm

    # Kubenetes testing:
    kubectx # kubectx & kubens
    kubeswitch
    stern # multi-pod tail
    minikube
    # Broken 20230202 docker-machine-kvm2  # kvm2 driver for minikube
    # awscli-local
    google-cloud-sdk
    skopeo # inspect information on images

    nerdctl
    rootlesskit # maybe for nerdctl/containerd

    kubectl-doctor # doctor?
    trivy #  Aqua Security - security scanner

    kubescape # Kubescape vuln scanner?

    # libkrun work? (with overlay)
    crun
    libkrun
    libkrunfw
    gvisor
    youki
    openlens
  ];
}
