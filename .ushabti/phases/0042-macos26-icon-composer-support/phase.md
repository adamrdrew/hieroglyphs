# Phase 0042: macOS 26 Icon Composer Icon Support

## Intent

Adopt macOS 26's Liquid Glass app icon system by compiling the existing `.icon` placeholder into `Assets.car` and `AppIcon.icns`, updating the Info.plist with the required keys, and integrating the compiled assets into the app bundle build pipeline. This infrastructure work enables proper app icon display on macOS 26 and eliminates the default "squircle prison" treatment. The actual icon artwork will be replaced separately — this phase builds the pipeline with the existing placeholder.

## Scope

**In scope:**
- Compile `AppIcon.icon` to `Assets.car` and `AppIcon.icns` using `xcrun actool`
- Update `Info.plist` to include `CFBundleIconName` (for Assets.car lookup) and retain `CFBundleIconFile` (legacy fallback)
- Modify `Scripts/build-app.sh` to copy compiled assets to `Contents/Resources/` in the app bundle
- Document the `actool` recompilation command for future icon updates
- Verify the app displays the compiled icon (even though it's a placeholder) without "squircle prison"

**Out of scope:**
- Creating new icon artwork (the placeholder gradient icon suffices)
- Modifying Package.swift resource declarations beyond what's necessary for bundle assembly
- Automating icon compilation on every build (compile once, check in the artefacts)

## Constraints

- **L03:** No Xcode project files. The `actool` compilation is a manual/scripted step, separate from `swift build`.
- **L07:** macOS 26 exclusively. No legacy platform considerations.
- **L18:** Adopt macOS 26 Liquid Glass design language (icon format is part of this).

## Acceptance Criteria

1. `Assets.car` and `AppIcon.icns` exist in `Sources/Hieroglyphs/Resources/` and are produced by `actool` from `AppIcon.icon/`.
2. `Info.plist` includes both `CFBundleIconName` and `CFBundleIconFile` keys.
3. `build-app.sh` copies both `Assets.car` and `AppIcon.icns` to the app bundle's `Contents/Resources/`.
4. The built app (`Hieroglyphs.app`) displays an icon without the default squircle treatment.
5. A comment or script documents the `actool` command for re-compiling when icon artwork changes.
6. `./Scripts/build-app.sh` exits 0.

## Risks / Notes

- The existing `icon.json` in `AppIcon.icon/` is a valid placeholder (gradient fill, no layers). It compiles but will be replaced with real artwork later.
- The phase prompt mentions "extensive detail on the `.icon` format, `actool` flags, and bundle structure in the card body" — but since no card file exists, Builder should refer to Apple's documentation and standard `actool` usage for Icon Composer (macOS 26).
- Compiled assets (`Assets.car`, `AppIcon.icns`) will be checked into version control because icon changes are rare and pre-compiling is simpler than compiling on every build.
