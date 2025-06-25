# AppImage Install

A simple shell script to install `.AppImage` applications on any Linux system.
It automatically moves the AppImage to a designated folder, ensures it is
executable, extracts the icon, and creates a `.desktop` launcher for integration
with your desktop environment (e.g., application menus, launchers).

![1750875225_grim](https://github.com/user-attachments/assets/ffa0aca9-728d-4498-8134-e6bd29316e1d)

## Features

- Moves `.AppImage` files to `~/AppImages`
- Ensures executable permission is set
- Extracts the first available icon (if found)
- Creates a `.desktop` file for menu integration
- Supports `appimage-run` for sandboxed execution (optional)

## Requirements

- `zsh` (or modify for bash)
- `7z` or `bsdtar` (for icon extraction)
- `appimage-run` (optional, used by default)
- Desktop environment that respects `.desktop` files

## Installation

### Option 1: Traditional Installation (Any Linux Distribution)

1. Clone the repository:

    ```bash
    git clone https://github.com/rxtsel/appimage-install
    cd appimage-install
    ```

2. Make the script executable:

    ```bash
    chmod +x appimage-install.sh
    ```

3. Move the script to a location in your `$PATH`:

    ```bash
    mkdir -p ~/.local/bin
    cp appimage-install.sh ~/.local/bin/appimage-install
    ```

4. Ensure `~/.local/bin` is in your `$PATH`:

      - For `bash`:

        ```bash
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
        ```

      - For `zsh`:

          ```bash
          echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
          source ~/.zshrc
        ```

### Option 2: Nix Flake Installation (Recommended for NixOS/Nix users)

#### Direct Installation from GitHub

Install directly using the flake:

```bash
nix profile install github:rxtsel/appimage-install
```

#### Local Development/Testing

1. Clone and enter the repository:

    ```bash
    git clone https://github.com/rxtsel/appimage-install
    cd appimage-install
    ```

2. Enter the development shell (includes all dependencies):

    ```bash
    nix develop
    ```

3. Or run directly:

    ```bash
    nix run . -- /path/to/your-app.AppImage
    ```

#### Home Manager Integration

Add to your `home.nix`:

```nix
{
  # Add the flake as an input in your flake.nix
  inputs.appimage-install.url = "github:rxtsel/appimage-install";

  # In your home.nix configuration:
  home.packages = [
    inputs.appimage-install.packages.${system}.default
  ];
}
```

Then apply changes:

```bash
home-manager switch
```

#### NixOS System Configuration

Add to your `configuration.nix`:

```nix
{
  # Add as flake input, then in your configuration:
  environment.systemPackages = [
    inputs.appimage-install.packages.${system}.default
  ];
}
```

#### Manual Nix Installation (without flakes)

If you prefer not to use flakes, install the dependencies manually:

```bash
nix profile install nixpkgs#appimage-run nixpkgs#p7zip
```

Then follow the traditional installation method above.

## Configuration

> [!IMPORTANT]
> This script uses `APPIMAGE_EXEC` variable with `appimage-run` by default for
> sandboxed execution (especially useful on NixOS), but you can change it to run 
> `.AppImage` files directly if your system doesn't require `appimage-run`.

By default, the script uses:

```sh
APPIMAGE_EXEC="appimage-run"
```

**If your system does NOT require `appimage-run`:**

Edit the script and change line 8 to:

```sh
APPIMAGE_EXEC=""
```

This will execute the `.AppImage` directly without sandboxing.

## Usage

Once installed as `appimage-install`, you can use it as follows:

```bash
appimage-install /path/to/your-app.AppImage
```

You will be prompted for:

- The display name (used in menus)
- Optionally editing the `.desktop` file

After completion, the application will appear in your system menu.

## Example

```bash
appimage-install ~/Downloads/Obsidian-1.5.0.AppImage
```

## Dependencies

The Nix flake automatically provides all required dependencies:
- `appimage-run` - For sandboxed AppImage execution
- `p7zip` - For icon extraction from AppImage files

For non-Nix systems, ensure these are installed through your package manager.
