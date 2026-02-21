#!/usr/bin/env bash
#
# package-dmg.sh
#
# Builds Hieroglyphs, assembles the .app bundle, and creates a DMG.
#
# Usage:
#   ./Scripts/package-dmg.sh [version]
#
# If version is not provided, reads from Sources/Hieroglyphs/Resources/Info.plist.
#
# Output:
#   .build/Hieroglyphs-<version>.dmg
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Hieroglyphs"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Get version from argument or Info.plist
if [ -n "$1" ]; then
  VERSION="$1"
else
  VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PROJECT_DIR/Sources/Hieroglyphs/Resources/Info.plist")
fi

DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "=== Building $APP_NAME $VERSION ==="

# Build the .app bundle
"$SCRIPT_DIR/build-app.sh"

# Remove old DMG if it exists
rm -f "$DMG_PATH"

echo "Creating DMG..."

# Create a temporary directory for DMG contents
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy .app to staging
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "$DMG_STAGING/Applications"

# Create the DMG
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

# Clean up staging
rm -rf "$DMG_STAGING"

echo "=== Created: $DMG_PATH ==="
echo "SHA256: $(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
