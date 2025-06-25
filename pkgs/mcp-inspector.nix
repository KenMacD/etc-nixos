{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  jq,
  ...
}:
# Source: https://github.com/andoriyu/flakes/blob/501a8d446c40e914a9e1b27f3cd40484807a6848/packages/mcp-inspector/default.nix
# Modified to set PATH to include node (See https://github.com/andoriyu/flakes/pull/258)
buildNpmPackage rec {
  pname = "mcp-inspector";
  version = "0.14.3";

  src = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "inspector";
    rev = version;
    # sha256 = "sha256-Yelijo9YIpZXotXhaxduNaP++8uKUaGnx59KsVeEpNc=";
    # hash = lib.fakeHash;
    hash = "sha256-tS3SAgg3BOjEPs+aDK7gQDgwm8aHB4GukqMeUHm+BLQ=";
  };

  postPatch = ''
    ${jq}/bin/jq '.packages["node_modules/router/node_modules/path-to-regexp"] += {
      resolved: "https://registry.npmjs.org/path-to-regexp/-/path-to-regexp-8.2.0.tgz",
      integrity: "sha512-TdrF7fW9Rphjq4RjrW0Kp2AW0Ahwu9sRGTkS6bvDi0SCwZlEZYmcfDbEsTz8RVk0EHIS/Vd1bv3JhG+1xZuAyQ=="
    }' package-lock.json > package-lock.json.new
    mv package-lock.json.new package-lock.json
    sed -i 's/\.allowExcessArguments()/\.allowExcessArguments?.()/g' cli/src/cli.ts
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        nodejs
      ]
    }"
  ];

  # npmDepsHash = "sha256-YV7+QdQwrQslj4Tw6lGEiLiYUe4NdfUotF2UxJGZe4I=";
  npmDepsHash = "sha256-BmctXkE8jlzWkSbDSl/pKNv8VmqMZ7/rkFeWisoOJg4=";

  doCheck = false;

  meta = with lib; {
    description = "Visual testing tool for MCP servers";
    homepage = "https://github.com/modelcontextprotocol/inspector";
    license = licenses.mit;
    maintainers = ["andoriyu@gmail.com"];
    platforms = platforms.all;
  };
}
