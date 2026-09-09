#!/bin/sh
# DartNative — SDK installer.
#
#   curl -fsSL https://cdn.dartnative.com/install.sh | sh
#
# Downloads the dn SDK, unpacks it to ~/zero, and adds ~/zero/bin to your PATH.
# Re-run any time to update: your engine cache is preserved, so updates are fast.
#
# Published to R2 by scripts/package-sdk.sh --publish (served at
# cdn.dartnative.com/install.sh) — keep it POSIX sh, it is piped straight to sh.
#
# Env overrides: DN_INSTALL_DIR (default ~/zero), DN_SDK_URL, DN_CDN.
set -eu

CDN="${DN_CDN:-https://cdn.dartnative.com}"
URL="${DN_SDK_URL:-$CDN/dn_infra/sdk/latest/dn-sdk.tar.gz}"
DEST="${DN_INSTALL_DIR:-$HOME/zero}"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

for tool in curl tar git; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is required but not installed"
done
# git is not optional: the SDK resolves its version and engine pin from the
# repository it ships as (see PATCHES.md → 0025).

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

say "▸ downloading the dn SDK"
curl -fsSL "$URL" -o "$TMP/dn-sdk.tar.gz" || die "download failed: $URL"

# Verify the checksum when one is published next to the tarball.
if curl -fsSL "$URL.sha256" -o "$TMP/sum" 2>/dev/null; then
  want="$(cut -d' ' -f1 < "$TMP/sum")"
  got="$( { shasum -a 256 "$TMP/dn-sdk.tar.gz" 2>/dev/null || sha256sum "$TMP/dn-sdk.tar.gz"; } | cut -d' ' -f1 )"
  [ "$want" = "$got" ] || die "checksum mismatch — expected $want, got $got"
  say "  checksum verified"
fi

say "▸ unpacking to $DEST"
mkdir -p "$TMP/x"
tar -xzf "$TMP/dn-sdk.tar.gz" -C "$TMP/x"
[ -d "$TMP/x/zero" ] || die "unexpected archive layout (no zero/ at the root)"

if [ -d "$DEST" ]; then
  # Keep the downloaded Dart SDK + engine artifacts (~600 MB) across updates.
  [ -d "$DEST/bin/cache" ] && mv "$DEST/bin/cache" "$TMP/cache-keep"
  rm -rf "$DEST"
fi
mkdir -p "$(dirname "$DEST")"
mv "$TMP/x/zero" "$DEST"
if [ -d "$TMP/cache-keep" ]; then
  mv "$TMP/cache-keep" "$DEST/bin/cache"
  say "  kept the existing engine cache"
fi

BIN="$DEST/bin"
case ":${PATH-}:" in
  *":$BIN:"*) ON_PATH=1 ;;
  *)          ON_PATH=0 ;;
esac

# Add to the profile of the user's login shell. A piped `| sh` runs in a
# subshell and cannot export into the caller's session, so this is the only way
# `dn` survives the install.
case "${SHELL##*/}" in
  zsh)  PROFILE="$HOME/.zshrc" ;;
  bash) if [ -f "$HOME/.bash_profile" ]; then PROFILE="$HOME/.bash_profile"; else PROFILE="$HOME/.bashrc"; fi ;;
  *)    PROFILE="$HOME/.profile" ;;
esac
LINE="export PATH=\"$BIN:\$PATH\""
if ! grep -qs -- "$BIN" "$PROFILE" 2>/dev/null; then
  printf '\n# DartNative (dn)\n%s\n' "$LINE" >> "$PROFILE"
  say "▸ added $BIN to PATH in $PROFILE"
else
  say "▸ PATH already configured in $PROFILE"
fi

say ""
say "✓ dn installed to $DEST"
say ""
if [ "$ON_PATH" -eq 0 ]; then
  say "  Open a new terminal (or run: $LINE), then:"
else
  say "▸ a terminal opened before this install keeps its old PATH: open a new one, or run $BIN/dn by path"
  say "  Next:"
fi
say "    dn --version    # first run downloads the engine (~315 MB for iOS)"
say "    dn create my_app && cd my_app && dn run"
