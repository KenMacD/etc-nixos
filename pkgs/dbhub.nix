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
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = "bytebase";
    repo = "dbhub";
    rev = "e2ba067178a6f9043acf103dd92d40e9cf2a8016";
    hash = "sha256-UA3IwOk8C6X9PFAOOGjbSCFvgE+iMiJoBFHyNMTjGeQ=";
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
    hash = "sha256-NzmqPuJ9kHnJTG6a4JCjTYkq50t74vhnUuLrvk4s3fM=";
    pnpmWorkspaces = ["." "frontend"];
  };

  buildPhase = ''
    runHook preBuild

    # pnpmConfigHook handles the install from pnpmDeps
    # Patch shebangs in all node_modules scripts
    patchShebangs node_modules
    patchShebangs frontend/node_modules

    # Build better-sqlite3 native bindings
    cd node_modules/better-sqlite3
    npm run build-release --offline --nodedir="${nodejs}"
    rm -rf build/Release/{.deps,obj,obj.target,test_extension.node}
    find build -type f -exec \
      ${binutils-unwrapped}/bin/remove-references-to \
      -t "${nodejs}" {} \;
    cd ../..

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
