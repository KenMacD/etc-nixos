{ config, lib, pkgs, ... }:

with lib;

{
  security.apparmor.enable = mkDefault true;
  security.sudo.execWheelOnly = mkDefault true;

  # environment.memoryAllocator.provider = mkDefault "scudo";
  # environment.variables.SCUDO_OPTIONS = mkDefault "ZeroContents=1";

  # set up other allocators for use with LD_PRELOAD
  environment.variables = {
    MALLOC_HARDENED = "${pkgs.graphene-hardened-malloc}/lib/libhardened_malloc.so";
    MALLOC_JEMALLOC = "${pkgs.jemalloc}/lib/libjemalloc.so";
    MALLOC_SCUDO = "${pkgs.llvmPackages_latest.compiler-rt}/lib/linux/libclang_rt.scudo-x86_64.so";
    MALLOC_MIMALLOC = "${pkgs.mimalloc}/lib/libmimalloc.so";
  };

  # Some configs pulled from modules/profiles/hardened
  # Also see https://github.com/torvalds/linux/blob/master/security/Kconfig.hardening
  # and https://github.com/a13xp0p0v/kconfig-hardened-check/blob/2b5bf3548b6a7edbf7cd74278d570b658f9ab34a/kconfig_hardened_check/__init__.py#L13-L21
  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25"
    "netrom"
    "rose"

    # Old or rare or insufficiently audited filesystems
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    "erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs"
  ];
}
