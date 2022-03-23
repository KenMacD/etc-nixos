self: super:
let
  version = "2.1.4";
  src = self.fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    rev = "zfs-${version}";
    sha256 = "sha256-pHz1N2j+d9p1xleEBwwrmK9mN5gEyM69Suy0dsrkZT4=";
  };
in
{
  linuxPackages_zen = super.linuxPackages_zen.extend (linuxPackagesSelf: linuxPackagesSuper: {
    zfs = linuxPackagesSuper.zfs.overrideAttrs (_: {
      name = "zfs-kernel-${version}-${linuxPackagesSuper.kernel.version}";
      inherit src;
    }
    );
  });

  zfs = super.zfs.overrideAttrs (_: {
    name = "zfs-user-${version}";
    inherit src;
  });
}
