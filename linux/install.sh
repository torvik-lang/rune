#!/usr/bin/env sh
# install.sh - rune installer (the Torvik package manager):
#   curl -fsSL https://raw.githubusercontent.com/torvik-lang/rune/main/linux/install.sh | sh
#
# rune is versioned and released independently from Torvik, from its own repo.
# This installs just rune into ~/.torvik/bin (the same place Torvik uses),
# alongside an existing torvc. You usually won't run this directly: the Torvik
# installer already pulls rune for you. It's here for a rune-only install or a
# `rune self-update`. Pin a version with RUNE_VERSION=v1.4.0.
set -e
INSTALL_DIR="$HOME/.torvik"; BIN_DIR="$INSTALL_DIR/bin"
ORG="https://github.com/torvik-lang/rune"
RAW="https://raw.githubusercontent.com/torvik-lang/rune/main"
fetch() { if command -v curl >/dev/null 2>&1; then curl -fsSL "$1"; else wget -qO- "$1"; fi; }
dl() { if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"; else wget -qO "$2" "$1"; fi; }

OS=$(uname -s | tr '[:upper:]' '[:lower:]'); ARCH=$(uname -m)
case "$ARCH" in x86_64|amd64) ARCH=x86_64;; aarch64|arm64) ARCH=aarch64;; *) echo "error: unsupported arch $ARCH"; exit 1;; esac
case "$OS" in linux|darwin) : ;; *) echo "error: unsupported OS $OS"; exit 1;; esac

if [ -n "$RUNE_VERSION" ]; then
    V="${RUNE_VERSION#v}"
else
    V="$(fetch "$RAW/VERSION" | grep -E '^[[:space:]]*rune' | head -1 | sed 's/^[^=]*=[[:space:]]*//' | tr -d '[:space:]')"
    [ -n "$V" ] || { echo "error: could not determine the latest rune version (network or GitHub error)."; exit 1; }
fi
echo "Installing rune v$V ($OS/$ARCH)..."
mkdir -p "$BIN_DIR"
if ! dl "$ORG/releases/download/v$V/rune-$OS-$ARCH" "$BIN_DIR/rune.new" 2>/dev/null; then
    echo "error: rune v$V has no $OS/$ARCH build."
    echo "  See https://github.com/torvik-lang/rune/releases"
    rm -f "$BIN_DIR/rune.new"; exit 1
fi
mv "$BIN_DIR/rune.new" "$BIN_DIR/rune"; chmod +x "$BIN_DIR/rune"
printf 'rune = %s\n' "$V" > "$INSTALL_DIR/rune.VERSION"

PATH_LINE='export PATH="$HOME/.torvik/bin:$PATH"'
add_to_rc() { [ -f "$1" ] || touch "$1"; grep -q ".torvik/bin" "$1" 2>/dev/null || printf '\n# Torvik\n%s\n' "$PATH_LINE" >> "$1"; }
case "${SHELL##*/}" in
  zsh)  add_to_rc "$HOME/.zshrc"; add_to_rc "$HOME/.profile" ;;
  fish) mkdir -p "$HOME/.config/fish"; grep -q ".torvik" "$HOME/.config/fish/config.fish" 2>/dev/null || printf '\n# Torvik\nset -gx PATH $HOME/.torvik/bin $PATH\n' >> "$HOME/.config/fish/config.fish" ;;
  *)    add_to_rc "$HOME/.bashrc"; add_to_rc "$HOME/.profile" ;;
esac

echo ""
echo "rune v$V installed."
if ! command -v torvc >/dev/null 2>&1 && [ ! -x "$BIN_DIR/torvc" ]; then
    echo "note: Torvik (torvc) isn't installed yet. rune manages Torvik but needs it to build projects:"
    echo "  curl -fsSL https://raw.githubusercontent.com/torvik-lang/torvik/main/linux/install.sh | sh"
fi
echo ">>> Open a new terminal (or run: . ~/.bashrc), then:  rune version"

# One-shot: if run from a downloaded file, remove it. Skipped when piped (curl | sh).
case "$0" in
  *install.sh) if [ -f "$0" ]; then rm -f -- "$0" 2>/dev/null || true; fi ;;
esac
