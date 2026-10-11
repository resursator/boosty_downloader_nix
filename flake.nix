{
  description = "Boosty Downloader CLI and GUI for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      version = "0.19.0";

      src = pkgs.fetchzip {
        url = "https://github.com/ath31st/boosty_downloader/archive/refs/tags/v${version}.tar.gz";
        hash = "sha256-ci9Ps+wgNUO5omrTc3we0dljyIOP9u4c0emAs9U/pqw=";
        stripRoot = true;
      };

      cli = pkgs.callPackage ./cli.nix {
        inherit src;
      };

      gui = pkgs.callPackage ./gui.nix {
        inherit src;
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
