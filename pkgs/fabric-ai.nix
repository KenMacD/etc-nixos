{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "fabric-ai";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "danielmiessler";
    repo = "fabric";
    rev = "v${version}";
    sha256 = "sha256-cCptzSC0wiWwS7t6U9sWlkNlJcMtFcgO8IaHgwq1fpw=";
  };

  vendorHash = "sha256-V7P5vtc1ahPHYH5vc72v1z1uLQN6Y1Ft7zabZ9U7F9c=";
  meta = with lib; {
    description = "An open-source framework for augmenting humans using AI";
    license = licenses.mit;
    maintainers = [ ];
  };
}
