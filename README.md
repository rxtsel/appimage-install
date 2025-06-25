# AppImage Installer

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

1. Clone the repository:

    ```bash
    git clone https://github.com/rxtsel/appimage-installer
    cd appimage-installer
    ```

2. Make the script executable:

    ```bash
    chmod +x install-appimage.sh
    ```

3. Move the script to a location in your `$PATH`:

    ```bash
    mkdir -p ~/.local/bin
    cp install-appimage.sh ~/.local/bin/appimage-install
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

> [!IMPORTANT]
> This script use `APPIMAGE_EXEC` variable with `appimage-run` by default for
run in NixOS, but you can change it to run `.AppImage` files directly if
your system does not require `appimage-run`.

By default, the script uses:

```sh
APPIMAGE_EXEC="appimage-run"
```

This allows sandboxed execution of `.AppImage` files.

**If your system does **not** require or use `appimage-run`**

Edit the script and change the line to:

```sh
APPIMAGE_EXEC=""
```

This will run the `.AppImage` directly.

---

### For NixOS

Add this to your `home.nix` (if using Home Manager):

```nix
home.sessionPath = [ "$HOME/.local/bin" ];
```

Then apply changes:

```bash
home-manager switch
```

Ensure `appimage-run` is installed:

```nix
home.packages = with pkgs; [
  appimage-run
  p7zip
];
```

Alternatively, run:

```bash
nix profile install nixpkgs#appimage-run
nix profile install nixpkgs#p7zip
```

---

## Usage

Once installed as `appimage-install`, you can use it as follows:

```bash
appimage-install /path/to/your-app.AppImage
```

You will be prompted for:

- The display name (used in menus)
- Optionally editing the `.desktop` file

After completion, the application will appear in your system menu.

---

## Example

```bash
appimage-install ~/Downloads/Obsidian-1.5.0.AppImage
```
