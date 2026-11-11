{
  lib,
  stdenvNoCC,
  fetchzip,
  installFonts,
}:
# From: https://github.com/nielmin/nixos-config/blob/2eb0a8ddb050ff2d03d865438f964f2fd10a05e0/packages/kibernetyk-mono/package.nix
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kibernetyk-mono";
  version = "1.0.1";

  __structuredAttrs = true;

  src = fetchzip {
    url = "https://github.com/PavloKilko/KibernetykMono/releases/download/v${finalAttrs.version}/KibernetykMono-v${finalAttrs.version}.zip";
    hash = "sha256-RhFtMGg/vqyVvz4Mk5iEoTjhooyAfNcYvKSn1KnROBk=";
  };

  nativeBuildInputs = [installFonts];

  strictDeps = true;

  meta = {
    description = "Geometric monospace typeface inspired by the Ukrainian Cybernetics School";
    license = lib.licenses.ofl;
    maintainers = with lib.maintainers; [];
    homepage = "https://github.com/PavloKilko/KibernetykMono";
  };
})
