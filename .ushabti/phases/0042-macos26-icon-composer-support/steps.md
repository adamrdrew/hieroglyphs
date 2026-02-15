# Steps

## S001: Compile AppIcon.icon with actool

**Intent:** Produce `Assets.car` and `AppIcon.icns` from the existing `AppIcon.icon/` using `actool`.

**Work:**
- Run `xcrun actool --compile <output-dir> --platform macosx --minimum-deployment-target 26.0 --app-icon AppIcon --output-partial-info-plist /tmp/PartialInfo.plist Sources/Hieroglyphs/Resources/AppIcon.icon/` (or equivalent command that produces both Assets.car and AppIcon.icns).
- Move the compiled `Assets.car` and `AppIcon.icns` to `Sources/Hieroglyphs/Resources/`.
- Verify both files exist and are non-zero in size.

**Done when:** `Assets.car` and `AppIcon.icns` exist in `Sources/Hieroglyphs/Resources/` and were produced by `actool`.

## S002: Update Info.plist with icon keys

**Intent:** Configure the app bundle to use the compiled icon assets for both modern and legacy lookup.

**Work:**
- Add `<key>CFBundleIconName</key><string>AppIcon</string>` to `Info.plist` (for macOS 26 Assets.car lookup).
- Retain the existing `<key>CFBundleIconFile</key><string>AppIcon</string>` (for legacy .icns fallback).

**Done when:** `Info.plist` contains both `CFBundleIconName` and `CFBundleIconFile` keys, both set to `AppIcon`.

## S003: Update build-app.sh to copy Assets.car and AppIcon.icns

**Intent:** Ensure both compiled icon assets are copied into the app bundle during build.

**Work:**
- Modify `Scripts/build-app.sh` to copy `Sources/Hieroglyphs/Resources/Assets.car` and `Sources/Hieroglyphs/Resources/AppIcon.icns` to `$RESOURCES_DIR` after copying Info.plist.
- Preserve the existing `AppIcon.icns` copy if it's already handled (verify the script doesn't already copy it, then add both explicitly).

**Done when:** `build-app.sh` includes commands to copy both `Assets.car` and `AppIcon.icns` to `Contents/Resources/`.

## S004: Update Package.swift resources

**Intent:** Declare both `Assets.car` and `AppIcon.icns` as package resources so they're available at runtime.

**Work:**
- Modify `Package.swift` target resources to include `.copy("Resources/Assets.car")` in addition to the existing `.copy("Resources/AppIcon.icns")`.
- Remove any conflicting resource declarations if necessary.

**Done when:** `Package.swift` declares both `Assets.car` and `AppIcon.icns` as copied resources.

## S005: Document icon recompilation process

**Intent:** Provide clear instructions for re-running `actool` when the icon artwork changes in the future.

**Work:**
- Add a script `Scripts/compile-icon.sh` that runs the `actool` command from S001 and moves the outputs to `Sources/Hieroglyphs/Resources/`.
- Make the script executable (`chmod +x`).
- Add a brief header comment explaining when and why to run it.

**Done when:** `Scripts/compile-icon.sh` exists, is executable, and documents the `actool` invocation.

## S006: Build and verify icon display

**Intent:** Confirm the built app displays the compiled icon without default squircle treatment.

**Work:**
- Run `./Scripts/build-app.sh`.
- Open the built `Hieroglyphs.app` in Finder and verify the icon displays (placeholder gradient, but recognizable).
- Optionally, launch the app and check the Dock icon.

**Done when:** `./Scripts/build-app.sh` exits 0 and the app bundle displays a non-default icon.

## S007: Run tests

**Intent:** Ensure existing tests pass with the updated Package.swift resource declarations.

**Work:**
- Run `swift test`.

**Done when:** All tests pass.
