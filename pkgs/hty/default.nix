{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  zig_0_16,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "hty";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "LatentEvals";
    repo = "hty";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KwMPwUieefEZX3dBUtsVXlzP/i7hYUZe6glomm7VDLg=";
  };

  deps = callPackage ./deps.nix {
    name = "hty-zig-cache-${finalAttrs.version}";
  };

  nativeBuildInputs = [zig_0_16];

  # zig 0.16's `--system` pkgdir flag forces single-threaded compilation (a
  # ReleaseFast build goes from ~1 min to hours), so deps are provided by
  # prefetching a zig global package cache instead (see deps.nix).
  preBuild = ''
    cp -r "${finalAttrs.deps}/." "$ZIG_GLOBAL_CACHE_DIR/"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
  '';

  # ReleaseSafe trips zig's translate-c on the fortify wrappers in the bundled
  # glibc 2.43 poll.h; ReleaseFast (what upstream CI uses) builds clean. CPU
  # baseline matches upstream's release binaries; version-string pins the
  # version since the source tarball has no git history for build.zig to probe.
  dontSetZigDefaultFlags = true;
  zigBuildFlags = [
    "-Dcpu=baseline"
    "-Doptimize=ReleaseFast"
    "-Dversion-string=${finalAttrs.version}"
  ];

  doCheck = false;

  # Drop the static libhty.a that `zig build install` ships alongside the CLI.
  postInstall = ''
    rm -f "$out/lib/libhty.a"
  '';

  meta = {
    description = "Headless terminal for AI agents, automation, and CI";
    homepage = "https://github.com/LatentEvals/hty";
    license = lib.licenses.mit; # README badge; the repo ships no LICENSE file
    maintainers = with lib.maintainers; [];
    mainProgram = "hty";
    inherit (zig_0_16.meta) platforms;
  };
})
