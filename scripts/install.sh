#!/usr/bin/env bash
#
# Loopback installer.
#
#   curl -fsSL https://raw.githubusercontent.com/sicparvisventures/loopback/main/scripts/install.sh | bash
#
# Downloads the latest Loopback.app release and installs it to /Applications
# (or ~/Applications when /Applications is not writable).
#
# Environment:
#   LOOPBACK_VERSION   Install a specific tag (e.g. v0.2.0) instead of latest.
#   LOOPBACK_PREFIX    Install directory. Default: /Applications
#
# Note this deliberately does what a browser download cannot: files fetched
# with curl carry no com.apple.quarantine attribute, so the app opens without
# the "unidentified developer" prompt. Builds are ad-hoc signed, not notarised.

set -euo pipefail

REPO="sicparvisventures/loopback"
APP_NAME="Loopback.app"
PREFIX="${LOOPBACK_PREFIX:-/Applications}"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
info()  { printf '==> %s\n' "$*"; }

die() { red "error: $*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "Loopback is macOS only (found $(uname -s))."

macos_major="$(sw_vers -productVersion | cut -d. -f1)"
if (( macos_major < 14 )); then
    die "Loopback requires macOS 14 (Sonoma) or later; this is $(sw_vers -productVersion)."
fi

command -v curl >/dev/null || die "curl is required."

# Resolve the release tag.
if [[ -n "${LOOPBACK_VERSION:-}" ]]; then
    TAG="$LOOPBACK_VERSION"
else
    info "Looking up the latest release"
    TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -1)"
    [[ -n "$TAG" ]] || die "could not determine the latest release. Is one published yet? https://github.com/$REPO/releases"
fi

VERSION="${TAG#v}"
ASSET="Loopback-$VERSION-macos-universal.zip"
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

info "Downloading Loopback $TAG"
curl -fsSL --proto '=https' --tlsv1.2 -o "$TMP/$ASSET" "$URL" \
    || die "download failed: $URL"

info "Unpacking"
ditto -x -k "$TMP/$ASSET" "$TMP/unpacked" || die "could not unpack $ASSET"
[[ -d "$TMP/unpacked/$APP_NAME" ]] || die "$APP_NAME not found inside the archive"

# Fall back to ~/Applications rather than demanding sudo.
if [[ ! -w "$PREFIX" ]]; then
    if [[ "$PREFIX" == "/Applications" ]]; then
        PREFIX="$HOME/Applications"
        mkdir -p "$PREFIX"
        info "/Applications is not writable, installing to $PREFIX"
    else
        die "$PREFIX is not writable."
    fi
fi

DEST="$PREFIX/$APP_NAME"
if [[ -e "$DEST" ]]; then
    info "Replacing the existing install at $DEST"
    rm -rf "$DEST"
fi

ditto "$TMP/unpacked/$APP_NAME" "$DEST"

# Belt and braces: strip quarantine in case the archive picked it up.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

green "Loopback $TAG installed to $DEST"
echo
echo "Launch it with:"
echo "    open -a \"$DEST\""
echo
echo "First run: grant Screen Recording in System Settings > Privacy & Security"
echo "so Loopback can capture meeting audio, then restart the app."
