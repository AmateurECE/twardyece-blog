{
  description = "Flake environment for blog.ethantwardy.com";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];
  in rec {
    devShells = forAllSystems(system:
      let pkgs = import nixpkgs {
          inherit system;
        };
      in {
        default = pkgs.mkShell {
          packages = [ pkgs.ruby pkgs.bundler ];
        };
      }
    );
  };
}
