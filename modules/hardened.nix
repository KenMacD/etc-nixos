{ config, lib, pkgs, ... }:

with lib;

{
  # set up other allocators for use with LD_PRELOAD
  environment.variables = {
    MALLOC_HARDENED = "${pkgs.graphene-hardened-malloc}/lib/libhardened_malloc.so";
    MALLOC_JEMALLOC = "${pkgs.jemalloc}/lib/libjemalloc.so";
    MALLOC_SCUDO = "${pkgs.llvmPackages_latest.compiler-rt}/lib/linux/libclang_rt.scudo-x86_64.so";
    MALLOC_MIMALLOC = "${pkgs.mimalloc}/lib/libmimalloc.so";
  };

  # Some configs pulled from modules/profiles/hardened
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
