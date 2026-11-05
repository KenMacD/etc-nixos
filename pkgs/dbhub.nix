{
  lib,
  stdenv,
  nodejs,
  pnpm_10,
  python3,
  binutils-unwrapped,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dbhub";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "bytebase";
    repo = "dbhub";
    rev = "v${finalAttrs.version}";
    hash = "sha256-U77WuLsTL1XKbuucq3azhnU+WHxXQ5jaI1C00Z1NXyc=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    python3
    binutils-unwrapped
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-nyQPTw0Ids1aN3vXO9ZjDWYkbXJOw+YlScBL+ssXQ1k=";
    pnpmWorkspaces = ["." "frontend"];
  };

  buildPhase = ''
    runHook preBuild

    # pnpmConfigHook handles the install from pnpmDeps
    # Patch shebangs in all node_modules scripts
    patchShebangs node_modules
    patchShebangs frontend/node_modules

    # Build backend and frontend
    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create output directory structure
    mkdir -p $out/lib/node_modules/dbhub
    mkdir -p $out/bin

    # Copy built artifacts
    cp -r dist $out/lib/node_modules/dbhub/

    # Copy node_modules preserving pnpm structure
    cp -r node_modules $out/lib/node_modules/dbhub/
    cp package.json $out/lib/node_modules/dbhub/

    # Create executable wrapper with absolute node path
    cat > $out/bin/dbhub << EOF
    #!${nodejs}/bin/node
    import('$out/lib/node_modules/dbhub/dist/index.js');
    EOF
    chmod +x $out/bin/dbhub

    runHook postInstall
  '';

  # Disable broken symlink check for pnpm workspace symlinks
  dontFixup = true;

  meta = {
    description = "Minimal, token-efficient Database MCP Server for PostgreSQL, MySQL, SQL Server, SQLite, MariaDB";
    homepage = "https://github.com/bytebase/dbhub";
    license = lib.licenses.mit;
    mainProgram = "dbhub";
  };
})
