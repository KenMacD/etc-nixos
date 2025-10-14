{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem, nodejs ? pkgs."nodejs_14"}:

let
  nodePackages = import ./default.nix {
    inherit pkgs system nodejs;
  };
in
nodePackages // {
  "@bytebase/dbhub" = nodePackages."@bytebase/dbhub".override {
    buildInputs = [
      pkgs.which
      pkgs.postgresql
      pkgs.postgresql.pg_config
    ];
  };
}
