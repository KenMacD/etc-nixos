{
  config,
  lib,
  pkgs,
  options,
  ...
}: {
  boot.postBootCommands = ''
    echo "always" > /sys/kernel/mm/transparent_hugepage/enabled
    echo "defer+madvise" > /sys/kernel/mm/transparent_hugepage/defrag
  '';

  users.users.kenny.extraGroups = [
    "kvm"
    "libvirtd"
  ];

  ########################################
  # Containers
  ########################################
  virtualisation = {
    containerd.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        swtpm.enable = true;
      };
      # Only care about host arch:
      qemu.package = pkgs.qemu_kvm;
    };

    # Search gcr.io as well
    containers.registries.search = options.virtualisation.containers.registries.search.default ++ ["gcr.io"];

    # Add when user USB redirection required:
    spiceUSBRedirection.enable = true;

    # Make podman-compose the default compose provider
    containers = {
      enable = true;
      containersConf.settings = {
        engine = {
          compose_warning_logs = false;
          compose_providers = ["${pkgs.podman-compose}/bin/podman-compose"];
        };
      };
    };

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    waydroid.enable = true;

    appvm = {
      enable = true;
      user = "kenny";
    };
  };

  environment.etc = {
    # Add supported upstream shortnames
    "containers/registries.conf.d/shortnames.conf".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/containers/shortnames/e580d22f8b6b63a1b87de40c62512539dfdf64f1/shortnames.conf";
      hash = "sha256-8RIK63nXSSZNFYp7pI9a/OU5/fZKdD2+OgUtIcanBLI=";
    };

    # Block any unverified shortnames (will ask in interactive cases)
    "containers/registries.conf.d/enforce.conf".text = ''
      short-name-mode="enforcing"
    '';

    # /run/libvirt/nix-ovmf/edk2-x86_64-code.fd
    "ovmf/edk2-x86_64-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-code.fd";
    };

    # /run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };

    # /run/libvirt/nix-ovmf/edk2-i386-vars.fd
    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
    };
  };

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

  # Start tray services
  environment.etc."sway/config.d/podman-desktop.conf".source = pkgs.writeText "podman-desktop.conf" ''
    exec ${pkgs.podman-desktop}/bin/podman-desktop
  '';

  environment.systemPackages = with pkgs; [
    buildah
    # TODO: broken 2025-10-25 https://github.com/NixOS/nixpkgs/issues/456842 cosign # Container Signing, Verification
    crane # crane digest <image>
    cri-tools
    diffoci # Diff container images
    distrobox
    dive # A tool for exploring a docker image
    landrun
    guestfs-tools # virt-customize -a ubuntu.img --root-password random
    libguestfs # guestfish / guestmount
    podman-compose
    podman-desktop
    podman-tui
    swtpm # Software tpm support
    trivy #  Aqua Security - vulnerability security scanner

    wget # needed for: lxc-create --template download

    # Testing gvisor runtime
    gvisor

    # Testing firecracker
    firecracker
    firectl
    flintlock
    # firecracker-containerd (doesn't exist)

    # Kubernetes stuff
    k9s
    kind
    krew # kubectl plugin manager
    kubectl
    kubectl-doctor # doctor?
    kubectx # kubectx & kubens
    kubecolor # kubectl with color output
    kubescape # Kubescape vuln scanner?
    kubernetes # kubeadm
    kubernetes-helm
    # openlens closed its source code?
    stern # multi-pod tail

    # Kubenetes testing:
    kubeswitch
    minikube
    docker-machine-kvm2 # kvm2 driver for minikube
    (google-cloud-sdk.withExtraComponents (
      with pkgs.google-cloud-sdk.components; [
        config-connector
      ]
    ))
    skopeo # inspect information on images

    nerdctl
    rootlesskit # maybe for nerdctl/containerd

    quickemu

    # libkrun work? (with overlay)
    crun
    libkrun
    libkrunfw
    youki
  ];
}
