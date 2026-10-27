{
  description = "Boosty Downloader CLI and GUI for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      version = "0.20.0";

      src = pkgs.fetchzip {
        url = "https://github.com/ath31st/boosty_downloader/archive/refs/tags/v${version}.tar.gz";
        hash = "sha256-p3Q36Pxi5OjSUtf7gtrkIwP5dFS+TzhK3nrQ3dhv8vM=";
        stripRoot = true;
      };

      cli = pkgs.callPackage ./cli.nix {
        inherit src;
        inherit version;
      };

      gui = pkgs.callPackage ./gui.nix {
        inherit src;
        inherit version;
      };
    in
    {
      packages.${system} = {
        inherit cli gui;
        default = cli;
      };

      apps.${system} = {
        cli = {
          type = "app";
          program = "${cli}/bin/boosty_downloader_cli";
        };

        gui = {
          type = "app";
          program = "${gui}/bin/boosty_downloader_gui";
        };

        default = self.apps.${system}.cli;
      };
    };
}
