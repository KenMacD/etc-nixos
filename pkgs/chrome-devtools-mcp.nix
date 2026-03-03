{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  bubblewrap,
  chromium,
  makeWrapper,
  runCommand,
}: let
  # Updated from https://github.com/aster-void/nix-repository/blob/6d6ea10bb4aaf087030c2aa9ca00746f8ab5b95e/packages/chrome-devtools-mcp/package.nix
  tag = "chrome-devtools-mcp-v0.18.1";
  unwrapped = buildNpmPackage {
    pname = "chrome-devtools-mcp-unwrapped";
    version = tag;
    src = fetchFromGitHub {
      owner = "ChromeDevTools";
      repo = "chrome-devtools-mcp";
      inherit tag;
      hash = "sha256-Tdgf3LjhSYKKZ46rfUJRQXuNjrjceezPUZfwarmlYp0=";
    };
    env = {
      PUPPETEER_SKIP_DOWNLOAD = "true";
    };

    buildPhase = ''
      runHook preBuild
      npm run bundle
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules/chrome-devtools-mcp
      cp -r build $out/lib/node_modules/chrome-devtools-mcp/
      cp package.json $out/lib/node_modules/chrome-devtools-mcp/
      chmod +x $out/lib/node_modules/chrome-devtools-mcp/build/src/index.js
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/chrome-devtools-mcp/build/src/index.js $out/bin/chrome-devtools-mcp
      runHook postInstall
    '';

    npmDepsHash = "sha256-zh7YYVhWwoj590nfKmoHHRt8v7+mBrsDvA7gPeKnMdE=";

    meta = {
      description = "Chrome DevTools for coding agents";
      homepage = "https://www.npmjs.com/package/chrome-devtools-mcp";
      license = lib.licenses.asl20;
      maintainers = [];
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
      mainProgram = "chrome-devtools-mcp";
    };
  };
  bwrapFlags = lib.lists.flatten [
    ["--ro-bind" "/" "/"]
    ["--dev-bind" "/dev" "/dev"]
    ["--proc" "/proc"]
    ["--bind" "/tmp" "/tmp"]
    ["--bind" "$HOME" "$HOME"]
    ["--tmpfs" "/opt"]
    ["--dir" "/opt/google/chrome"]
    ["--symlink" "${lib.getExe chromium}" "/opt/google/chrome/chrome"]
    ["--"]
    (lib.getExe unwrapped)
  ];
in
  runCommand "${tag}" {
    nativeBuildInputs = [makeWrapper];
    passthru = {inherit unwrapped;};
    meta =
      unwrapped.meta
      // {
        mainProgram = "chrome-devtools-mcp";
      };
  } ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe bubblewrap} $out/bin/chrome-devtools-mcp --add-flags ${
      lib.escapeShellArg
      (lib.concatStringsSep " " bwrapFlags)
    }
  ''
