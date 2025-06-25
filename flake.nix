{
  description = "rxtsel's AppImage Install shell script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        scriptPath = builtins.toString ./appimage-install.sh;

        appimage-install = pkgs.writeShellApplication {
          name = "appimage-install";
          runtimeInputs = with pkgs; [ appimage-run p7zip ];
          text = builtins.readFile scriptPath;
        };
      in {
        packages.default = appimage-install;

        apps.default = {
          type = "app";
          program = "${appimage-install}/bin/appimage-install";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            appimage-install
            pkgs.appimage-run
            pkgs.p7zip
          ];
        };
      });
}
