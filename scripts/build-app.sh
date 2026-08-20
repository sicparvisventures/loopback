#!/usr/bin/env bash
#
# Builds native/Loopback into a distributable Loopback.app bundle.
#
# SwiftPM produces a bare executable; macOS needs a bundle with an Info.plist
# to be a real app (dock icon, TCC permission prompts, Launch Services). This
# assembles that bundle, ad-hoc signs it, and zips it with ditto so the
# bundle's symlinks and metadata survive the round trip.
#
# Usage: scripts/build-app.sh [version]
#   version  Marketing version for CFBundleShortVersionString (default: 0.1.0)
#
# Output: dist/Loopback.app and dist/Loopback-<version>-macos-universal.zip

set -euo pipefail

VERSION="${1:-0.1.0}"
VERSION="${VERSION#v}"   # accept both "1.2.3" and the "v1.2.3" tag form

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$REPO_ROOT/native/Loopback"
DIST_DIR="$REPO_ROOT/dist"
APP="$DIST_DIR/Loopback.app"
ZIP="$DIST_DIR/Loopback-$VERSION-macos-universal.zip"

echo "==> Building Loopback $VERSION (universal: arm64 + x86_64)"
cd "$PACKAGE_DIR"
swift build -c release --arch arm64 --arch x86_64

BINARY="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Loopback"
if [[ ! -f "$BINARY" ]]; then
    echo "error: expected binary at $BINARY" >&2
    exit 1
fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/Loopback"
chmod +x "$APP/Contents/MacOS/Loopback"

# Info.plist still carries Xcode's $(EXECUTABLE_NAME) placeholder, which only
# Xcode expands. Substitute it here along with the version fields.
sed -e 's|\$(EXECUTABLE_NAME)|Loopback|g' \
    -e "s|<string>1\.0\.0</string>|<string>$VERSION</string>|" \
    "$PACKAGE_DIR/Loopback/Resources/Info.plist" > "$APP/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist" >/dev/null

printf 'APPL????' > "$APP/Contents/PkgInfo"

if [[ -f "$PACKAGE_DIR/Loopback/Resources/AppIcon.icns" ]]; then
    cp "$PACKAGE_DIR/Loopback/Resources/AppIcon.icns" "$APP/Contents/Resources/"
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
fi

# Ad-hoc signature. Without any signature at all, macOS refuses to launch
# arm64 binaries outright; ad-hoc at least gets past that. It is not
# notarised, so first launch still needs the right-click-Open dance or the
# quarantine flag stripped -- see scripts/install.sh and the README.
echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=2 "$APP" 2>&1 | sed 's/^/    /'

echo "==> Packaging $ZIP"
rm -f "$ZIP"
# ditto, not zip: it preserves the bundle structure Finder expects.
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo
echo "Built:"
echo "  $APP"
echo "  $ZIP  ($(du -h "$ZIP" | cut -f1))"
echo "  architectures: $(lipo -archs "$APP/Contents/MacOS/Loopback")"
