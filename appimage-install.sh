#!/usr/bin/env sh

# appimage-install: Install an AppImage into ~/.local with desktop entry + icon extraction.
# Compatible with POSIX sh (works in dash, bash, zsh in sh-mode, busybox sh).
# Requires: appimage-run, p7zip (7z). Optional: bsdtar, update-desktop-database.

set -eu

APPDIR="${HOME}/.local/share/applications"
ICONDIR="${HOME}/.local/share/icons"
DESTDIR="${HOME}/AppImages"

# Prefer absolute appimage-run if present in PATH anyway.
APPIMAGE_EXEC="${APPIMAGE_EXEC:-appimage-run}"

# ANSI colors (best-effort; if terminal doesn't support, it will just print raw)
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW="$(printf '\033[33m')"
RESET="$(printf '\033[0m')"

PADDING="%-8s"

log() {
  # shellcheck disable=SC2059
  printf "${PADDING} %s\n" "[*]" "$1"
}

success() {
  # shellcheck disable=SC2059
  printf "${GREEN}${PADDING}${RESET} %s\n" "[OK]" "$1"
}

warn() {
  # shellcheck disable=SC2059
  printf "${YELLOW}${PADDING}${RESET} %s\n" "[WARN]" "$1"
}

error() {
  # shellcheck disable=SC2059
  printf "${RED}${PADDING}${RESET} %s\n" "[ERROR]" "$1" >&2
}

# prompt "Message" ["DefaultValue"]
prompt() {
  message="$1"
  default="${2:-}"
  if [ -n "$default" ]; then
    # shellcheck disable=SC2059
    printf "${YELLOW}${PADDING}${RESET} %s" "[?]" "$message [$default]: "
  else
    # shellcheck disable=SC2059
    printf "${YELLOW}${PADDING}${RESET} %s" "[?]" "$message "
  fi
}

# read_line varname
read_line() {
  varname="$1"
  IFS= read -r _line || _line=""
  # POSIX-safe "assign by name"
  eval "$varname=\$_line"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# mktemp_dir: create a temp dir in a portable way
mktemp_dir() {
  if have_cmd mktemp; then
    mktemp -d 2>/dev/null && return 0
  fi
  # fallback
  d="${TMPDIR:-/tmp}/appimage-install.$$"
  (umask 077 && mkdir -p "$d") || return 1
  printf '%s\n' "$d"
}

sanitize_id() {
  # Lowercase, replace non-alnum with '-', collapse '-', trim '-'
  # Uses only POSIX tools (tr + sed).
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' -e 's/--*/-/g' -e 's/^-//' -e 's/-$//'
}

first_icon_in_dir() {
  # Find first png/svg; "find" is widely available on NixOS; still guard.
  d="$1"
  if have_cmd find; then
    find "$d" -type f \( -iname '*.png' -o -iname '*.svg' \) 2>/dev/null | sed -n '1p'
  else
    printf '%s\n' ""
  fi
}

extract_appimage_payload() {
  appimage="$1"
  outdir="$2"

  # Prefer 7z if present (you include p7zip in runtimeInputs)
  if have_cmd 7z; then
    7z x "$appimage" "-o$outdir" >/dev/null 2>&1 || true
    return 0
  fi

  # Fallback: bsdtar if present
  if have_cmd bsdtar; then
    bsdtar -xf "$appimage" -C "$outdir" >/dev/null 2>&1 || true
    return 0
  fi

  warn "No extractor found (7z/bsdtar). Skipping icon extraction."
  return 0
}

usage() {
  warn "USAGE: appimage-install path/to/AppImage"
}

# --- Validate arguments
if [ "$#" -lt 1 ]; then
  error "No AppImage file provided."
  usage
  exit 1
fi

APPIMAGE="$1"
if [ ! -f "$APPIMAGE" ]; then
  error "File not found: $APPIMAGE"
  exit 1
fi

# Ensure required tools exist
if ! have_cmd "$APPIMAGE_EXEC"; then
  warn "Command not found: ${APPIMAGE_EXEC}"
  warn "Your .desktop will use Exec=${APPIMAGE_EXEC} \"...\""
  warn "Make sure appimage-run is installed and available in PATH."
fi

FILENAME=$(basename "$APPIMAGE")
DEFAULT_NAME=${FILENAME%%.*}

prompt "How should this application appear in your system menus?" "$DEFAULT_NAME"
read_line DISPLAY_NAME
if [ -z "${DISPLAY_NAME:-}" ]; then
  DISPLAY_NAME="$DEFAULT_NAME"
fi

FILE_ID=$(sanitize_id "$DISPLAY_NAME")
if [ -z "$FILE_ID" ]; then
  # Fallback if name was only symbols/spaces
  FILE_ID=$(sanitize_id "$DEFAULT_NAME")
fi

RENAMED_APPIMAGE="${DESTDIR}/${FILE_ID}.AppImage"
DESKTOP_FILE="${APPDIR}/${FILE_ID}.desktop"

mkdir -p "$APPDIR" "$ICONDIR"

if [ ! -d "$DESTDIR" ]; then
  mkdir -p "$DESTDIR"
  success "Created AppImage directory at $DESTDIR"
else
  log "Using existing AppImage directory at $DESTDIR"
fi

# Make executable
if [ ! -x "$APPIMAGE" ]; then
  chmod +x "$APPIMAGE"
  success "Execution permission applied to $APPIMAGE"
fi

# Move and rename AppImage
if [ "$APPIMAGE" != "$RENAMED_APPIMAGE" ]; then
  if [ -f "$RENAMED_APPIMAGE" ]; then
    error "An AppImage with name '${FILE_ID}.AppImage' already exists in $DESTDIR."
    exit 1
  fi
  mv "$APPIMAGE" "$RENAMED_APPIMAGE"
  success "AppImage moved to $RENAMED_APPIMAGE"
else
  success "AppImage already in the correct location."
fi

# Ensure it's still executable
if [ ! -x "$RENAMED_APPIMAGE" ]; then
  chmod +x "$RENAMED_APPIMAGE"
  success "Execution permission applied to $RENAMED_APPIMAGE"
fi

# Extract icon
log "Searching for icons in the AppImage..."
ICON_PATH=""

TMPDIR="$(mktemp_dir)"
extract_appimage_payload "$RENAMED_APPIMAGE" "$TMPDIR"

FOUND_ICON="$(first_icon_in_dir "$TMPDIR" || true)"

if [ -n "$FOUND_ICON" ] && [ -f "$FOUND_ICON" ]; then
  EXT=${FOUND_ICON##*.}
  ICON_FILENAME="${FILE_ID}.${EXT}"
  cp "$FOUND_ICON" "${ICONDIR}/${ICON_FILENAME}"
  ICON_PATH="${ICONDIR}/${ICON_FILENAME}"
  success "Icon extracted to $ICON_PATH"
else
  log "No icon found, fallback to name as icon."
  ICON_PATH="$FILE_ID"
fi

rm -rf "$TMPDIR" >/dev/null 2>&1 || true

# Create .desktop file
# Notes:
# - Use absolute path for Icon when extracted.
# - Exec wraps the AppImage with appimage-run (or chosen runner).
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=${DISPLAY_NAME}
Exec=${APPIMAGE_EXEC} "${RENAMED_APPIMAGE}"
Icon=${ICON_PATH}
Type=Application
Categories=Utility;
Terminal=false
EOF

success ".desktop launcher created at $DESKTOP_FILE"

# Optional edit
prompt "Do you want to manually edit the .desktop file? [y/N]:"
read_line EDIT_DESKTOP
case "${EDIT_DESKTOP:-}" in
  y|Y)
    editor="${EDITOR:-nano}"
    if have_cmd "$editor"; then
      "$editor" "$DESKTOP_FILE"
    else
      warn "EDITOR '$editor' not found; falling back to nano if available."
      if have_cmd nano; then
        nano "$DESKTOP_FILE"
      else
        warn "No editor found. Skipping manual edit."
      fi
    fi
    ;;
  *)
    ;;
esac

# Update desktop database (optional)
if have_cmd update-desktop-database; then
  update-desktop-database "$APPDIR" >/dev/null 2>&1 || true
fi

success "${DISPLAY_NAME} was successfully installed and integrated."

