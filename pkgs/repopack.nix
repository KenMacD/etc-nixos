{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage
rec {
  pname = "repopack";
  version = "0.1.43";

  src = fetchFromGitHub {
    owner = "yamadashy";
    repo = pname;
    rev = "v${version}";
    #hash = "sha256-bdJSN1sd6b8jkj9VwPWyOCPqRYouDD0icAUyytTaiDQ=";
    hash = "sha256-OqVkOI6HqmW7Doaapc34CK6X1WfFHFtX/Et3WjCEp/w=";
  };

  # npmDepsHash = "sha256-xgSEWBeIL5XMIKs2PMPWfGS/XxO9Jv/6OqVBbJER6Hc=";
  npmDepsHash = "sha256-I6kJPVN/src0Bndb6oBwEdbKFVlFuUMDXaXOusvcBsE=";

  npmPackFlags = ["--ignore-scripts "];

  NODE_OPTIONS = "--openssl-legacy-provider ";

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/${pname}
    cp -r . $out/lib/node_modules/${pname}
    mkdir -p $out/bin
    ln -s $out/lib/node_modules/${pname}/bin/${pname}.js $out/bin/${pname}
    runHook postInstall
  '';

  meta = {
    description = "A tool that packs your entire repository into a single, AI-friendly file";
    homepage = "https://github.com/yamadashy/repopack";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [nebunebu];
  };
}
