#!/usr/bin/env bash
#
# build-app.sh
#
# Builds Hieroglyphs and assembles a macOS .app bundle.
#
# Usage:
#   ./Scripts/build-app.sh
#
# Output:
#   .build/Hieroglyphs.app
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Hieroglyphs"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "Building $APP_NAME (release)..."
swift build -c release

echo "Assembling app bundle..."

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BUILD_DIR/arm64-apple-macosx/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$PROJECT_DIR/Sources/Hieroglyphs/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$PROJECT_DIR/Sources/Hieroglyphs/Resources/Assets.car" "$RESOURCES_DIR/Assets.car"
cp "$PROJECT_DIR/Sources/Hieroglyphs/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

echo "Built: $APP_BUNDLE"
