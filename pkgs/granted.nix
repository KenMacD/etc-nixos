{ bash
, buildGoModule
, fetchFromGitHub

, withFish ? false
, fish

, lib
, makeWrapper
, xdg-utils
}:

buildGoModule rec {
  pname = "granted";
  version = "0.20.2";

  src = fetchFromGitHub {
    owner = "common-fate";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-0ZuH4z+Cr3xUkpQG/Jv3VOoBVcw3vfcY28OG4C/JYuU=";
  };

  proxyVendor = true;
  vendorHash = "sha256-lwbXHvBK4gurrvnW9Ql7UQr/XYKx1R/2GQeq4QZxvzo=";

  patches = [ ./granted-fish.patch ];
  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/common-fate/granted/internal/build.Version=v${version}"
    "-X github.com/common-fate/granted/internal/build.Commit=${src.rev}"
    "-X github.com/common-fate/granted/internal/build.Date=1970-01-01-00:00:01"
    "-X github.com/common-fate/granted/internal/build.BuiltBy=Nix"
  ];

  subPackages = [
    "cmd/granted"
  ];

  outputs = [ "out" ];

  postInstall = ''
    ln -s $out/bin/granted $out/bin/assumego

    # Install shell script
    install -Dm755 scripts/assume $out/bin/assume
    #substituteInPlace $out/bin/assume \
    #  --replace /bin/bash ${bash}/bin/bash

    wrapProgram $out/bin/assume \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}

  '' + lib.optionalString withFish ''
    # Install fish script
    install -Dm755 scripts/assume.fish $out/share/fish/vendor_functions.d/assume.fish
    substituteInPlace $out/share/fish/vendor_functions.d/assume.fish \
      --replace /bin/fish ${fish}/bin/fish
  '';

  meta = with lib; {
    description = "The easiest way to access your cloud.";
    homepage = "https://github.com/common-fate/granted";
    changelog = "https://github.com/common-fate/granted/releases/tag/${version}";
    license = licenses.mit;
  };
}
