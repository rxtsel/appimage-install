{
  description = "rxtsel's AppImage Installer shell script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        appimage-installer = pkgs.writeShellApplication {
          name = "appimage-install";
          runtimeInputs = with pkgs; [ appimage-run p7zip ];
          text = builtins.readFile ./appimage-install.sh;
        };
      in {
        packages.default = appimage-installer;

        apps.default = {
          type = "app";
          program = "${appimage-installer}/bin/appimage-install";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            appimage-installer
            pkgs.appimage-run
            pkgs.p7zip
          ];
        };
      });
}

