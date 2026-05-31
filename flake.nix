{
  description = "rxtsel's AppImage Install shell script";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        scriptPath = toString ./appimage-install.sh;
        appimage-install = pkgs.writeShellApplication {
          name = "appimage-install";
          # bash is already the runtime for writeShellApplication; p7zip provides 7z.
          runtimeInputs = with pkgs; [
            appimage-run
            p7zip
          ];
          # Pin appimage-run to the Nix store path so it's always found,
          # even if the user's PATH doesn't include it.
          # The script respects APPIMAGE_EXEC when set, and auto-detects otherwise.
          text = ''
            export APPIMAGE_EXEC="${pkgs.appimage-run}/bin/appimage-run"
            ${builtins.readFile scriptPath}
          '';
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
      }
    );
}
