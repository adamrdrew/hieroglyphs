#!/usr/bin/env bash
#
# compile-icon.sh
#
# Compiles AppIcon.icon/ into Assets.car and AppIcon.icns using actool.
#
# When to run:
#   - After modifying icon.json in AppIcon.icon/
#   - After replacing icon artwork
#
# Usage:
#   ./Scripts/compile-icon.sh
#
# Output:
#   Sources/Hieroglyphs/Resources/Assets.car
#   Sources/Hieroglyphs/Resources/AppIcon.icns
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ICON_SOURCE="$PROJECT_DIR/Sources/Hieroglyphs/Resources/AppIcon.icon"
RESOURCES_DIR="$PROJECT_DIR/Sources/Hieroglyphs/Resources"
TEMP_DIR="/tmp/claude/icon-compile"

echo "Compiling AppIcon.icon..."

mkdir -p "$TEMP_DIR"

xcrun actool \
  --compile "$TEMP_DIR" \
  --platform macosx \
  --minimum-deployment-target 26.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$TEMP_DIR/PartialInfo.plist" \
  "$ICON_SOURCE"

echo "Copying compiled assets to Resources..."

cp "$TEMP_DIR/Assets.car" "$RESOURCES_DIR/Assets.car"
cp "$TEMP_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

echo "Icon compilation complete:"
ls -lh "$RESOURCES_DIR/Assets.car" "$RESOURCES_DIR/AppIcon.icns"
