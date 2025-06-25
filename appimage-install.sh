#!/usr/bin/env zsh

set -e

APPDIR="$HOME/.local/share/applications"
ICONDIR="$HOME/.local/share/icons"
DESTDIR="$HOME/AppImages"
APPIMAGE_EXEC="appimage-run" # Change this if needed

# ANSI colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# For spaces
PADDING="%-8s"

log() {
  printf "$PADDING %s\n" "[*]" "$1"
}

success() {
  printf "${GREEN}$PADDING${RESET} %s\n" "[OK]" "$1"
}

error() {
  printf "${RED}$PADDING${RESET} %s\n" "[ERROR]" "$1" >&2
}

warn() {
  printf "${YELLOW}$PADDING${RESET} %s\n" "[WARN]" "$1"
}

prompt() {
  local message="$1"
  shift
  printf "${YELLOW}$PADDING${RESET} %s" "[?]" "$(printf "%s" "$message" "$@")"
}

# --- Validate argument
if (( $# == 0 )); then
  error "No AppImage file provided."
  warn "Usage: appimage-install path/to/AppImage"
  exit 1
fi

APPIMAGE="$1"
if [[ ! -f "$APPIMAGE" ]]; then
  error "File not found: $APPIMAGE"
  warn "Usage: appimage-install path/to/AppImage"
  exit 1
fi

FILENAME=$(basename "$APPIMAGE")
DEFAULT_NAME="${FILENAME%%.*}"

prompt "How should this application appear in your system menus? [%s]: " "$DEFAULT_NAME"
read -r DISPLAY_NAME
DISPLAY_NAME="${DISPLAY_NAME:-$DEFAULT_NAME}"

# --- Generate file name ID
FILE_ID=$(echo "$DISPLAY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
RENAMED_APPIMAGE="$DESTDIR/$FILE_ID.AppImage"
DESKTOP_FILE="$APPDIR/$FILE_ID.desktop"

mkdir -p "$APPDIR" "$ICONDIR"

if [[ ! -d "$DESTDIR" ]]; then
  mkdir -p "$DESTDIR"
  success "Created AppImage directory at $DESTDIR"
else
  log "Using existing AppImage directory at $DESTDIR"
fi

# --- Make executable
if [[ ! -x "$APPIMAGE" ]]; then
  chmod +x "$APPIMAGE"
  success "Execution permission applied to $APPIMAGE"
fi

# --- Move and rename AppImage
if [[ "$APPIMAGE" != "$RENAMED_APPIMAGE" ]]; then
  if [[ -f "$RENAMED_APPIMAGE" ]]; then
    error "An AppImage with name '$FILE_ID.AppImage' already exists in $DESTDIR."
    exit 1
  fi
  mv "$APPIMAGE" "$RENAMED_APPIMAGE"
  success "AppImage moved to $RENAMED_APPIMAGE"
else
  success "AppImage already in the correct location."
fi

# --- Ensure it's still executable
if [[ ! -x "$RENAMED_APPIMAGE" ]]; then
  chmod +x "$RENAMED_APPIMAGE"
  success "Execution permission applied to $RENAMED_APPIMAGE"
fi

# --- Extract icon
log "Searching for icons in the AppImage..."
ICON_PATH=""
TMPDIR=$(mktemp -d)

if command -v 7z &> /dev/null; then
  7z x "$RENAMED_APPIMAGE" -o"$TMPDIR" > /dev/null 2>&1 || true
elif command -v bsdtar &> /dev/null; then
  bsdtar -xf "$RENAMED_APPIMAGE" -C "$TMPDIR" || true
fi

FOUND_ICON=$(find "$TMPDIR" -type f \( -iname '*.png' -o -iname '*.svg' \) | head -n 1 || true)

if [[ -n "$FOUND_ICON" ]]; then
  EXT="${FOUND_ICON##*.}"
  ICON_FILENAME="$FILE_ID.$EXT"
  cp "$FOUND_ICON" "$ICONDIR/$ICON_FILENAME"
  ICON_PATH="$ICONDIR/$ICON_FILENAME"
  success "Icon extracted to $ICON_PATH"
else
  log "No icon found, fallback to name as icon."
  ICON_PATH="$FILE_ID"
fi

rm -rf "$TMPDIR"

# --- Create .desktop file
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$DISPLAY_NAME
Exec=$APPIMAGE_EXEC "$RENAMED_APPIMAGE"
Icon=$ICON_PATH
Type=Application
Categories=Utility;
Terminal=false
EOF

success ".desktop launcher created at $DESKTOP_FILE"

# --- Optional edit
prompt "Do you want to manually edit the .desktop file? [y/N]: "
read -r EDIT_DESKTOP
if [[ "$EDIT_DESKTOP" =~ ^[Yy]$ ]]; then
  ${EDITOR:-nano} "$DESKTOP_FILE"
fi

# --- Update desktop db
if command -v update-desktop-database &> /dev/null; then
  update-desktop-database "$APPDIR" > /dev/null 2>&1 || true
fi

success "$DISPLAY_NAME was successfully installed and integrated."

