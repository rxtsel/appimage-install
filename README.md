# AppImage Install

A shell script to install `.AppImage` applications on any Linux system.
Moves the AppImage to a dedicated folder, sets executable permissions,
extracts the icon, and creates a `.desktop` launcher for desktop environment
integration (application menus, launchers, etc).

## Features

- Moves `.AppImage` files to `~/AppImages`
- Cleans up the display name automatically (strips version numbers, arch suffixes)
- Sets executable permissions
- Extracts the app icon (if found)
- Creates a `.desktop` file for menu integration
- Auto-detects whether `appimage-run` is needed (NixOS and similar systems)
- OS-aware install hints when optional dependencies are missing

## Requirements

- `bash`
- `7z` or `bsdtar` — for icon extraction (optional but recommended)
- `appimage-run` — auto-detected; required on NixOS and systems without a standard dynamic linker

## Installation

### Option 1: Nix Flake (recommended for NixOS/Nix users)

**Direct install from GitHub:**

```bash
nix profile install github:rxtsel/appimage-install --no-write-lock-file
```

**Run without installing:**

```bash
nix run github:rxtsel/appimage-install -- /path/to/your-app.AppImage
```

**Local development:**

```bash
git clone https://github.com/rxtsel/appimage-install
cd appimage-install
nix develop        # enter shell with all dependencies
nix run . -- /path/to/your-app.AppImage
```

**Home Manager (`home.nix`):**

```nix
{
  inputs.appimage-install.url = "github:rxtsel/appimage-install";

  home.packages = [
    inputs.appimage-install.packages.${system}.default
  ];
}
```

**NixOS system (`configuration.nix`):**

```nix
{
  environment.systemPackages = [
    inputs.appimage-install.packages.${system}.default
  ];
}
```

### Option 2: Traditional (any Linux distribution)

```bash
git clone https://github.com/rxtsel/appimage-install
cd appimage-install
chmod +x appimage-install.sh
mkdir -p ~/.local/bin
cp appimage-install.sh ~/.local/bin/appimage-install
```

Ensure `~/.local/bin` is in your `$PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Install dependencies for icon extraction (optional):

| Distro | Command |
|--------|---------|
| NixOS | `nix profile install nixpkgs#p7zip` |
| Arch | `sudo pacman -S p7zip` |
| Debian/Ubuntu | `sudo apt install p7zip-full` |
| Fedora | `sudo dnf install p7zip` |

## Usage

```bash
appimage-install /path/to/your-app.AppImage
```

You will be prompted for the display name (pre-filled with a cleaned-up version
of the filename), and optionally to open the `.desktop` file in your editor.

## Example

```bash
appimage-install ~/Downloads/Obsidian-1.5.0.AppImage
# → suggests "Obsidian" as the display name
```

```
AppImage Installer
──────────────────

[?]      Application name (for system menus) [Obsidian]:

[*]      Name     : Obsidian
[*]      ID       : obsidian
[*]      AppImage : /home/user/AppImages/obsidian.AppImage
[*]      Desktop  : /home/user/.local/share/applications/obsidian.desktop

[OK]     Moved to: /home/user/AppImages/obsidian.AppImage
[OK]     Icon saved: /home/user/.local/share/icons/obsidian.png
[OK]     .desktop created: /home/user/.local/share/applications/obsidian.desktop

[?]      Open the .desktop file in your editor? [y/N]

[OK]     Obsidian installed and integrated successfully.
```

## Files created

| Path | Description |
|------|-------------|
| `~/AppImages/<id>.AppImage` | The AppImage, renamed by display name |
| `~/.local/share/icons/<id>.png` | Extracted icon |
| `~/.local/share/applications/<id>.desktop` | Desktop launcher |
