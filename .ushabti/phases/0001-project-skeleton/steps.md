# Steps

## S001: Create directory structure

**Intent:** Establish the canonical directory layout per style guide.

**Work:**
- Create Sources/Hieroglyphs/
- Create Sources/Hieroglyphs/Models/
- Create Sources/Hieroglyphs/Services/
- Create Sources/Hieroglyphs/Views/
- Create Sources/Hieroglyphs/Utilities/
- Create Tests/HieroglyphsTests/
- Create Scripts/
- Create Resources/

**Done when:** All directories exist and are committed to version control.

---

## S002: Write Package.swift

**Intent:** Define the Swift Package Manager manifest with dependencies and build configuration.

**Work:**
- Declare package with name "Hieroglyphs"
- Set platform to macOS 26
- Add dependencies:
  - CodeEditorView: https://github.com/mchakravarty/CodeEditorView (v0.15.4 or compatible)
  - swift-markdown-ui: https://github.com/gonzalezreal/swift-markdown-ui (v2.4.1 or compatible)
- Define executable target "Hieroglyphs" depending on CodeEditorView and MarkdownUI
- Define test target "HieroglyphsTests" depending on Hieroglyphs target

**Done when:** `swift build` resolves dependencies and compiles successfully (even with no source files yet).

---

## S003: Write App.swift

**Intent:** Create the @main entry point and Window scene.

**Work:**
- Create Sources/Hieroglyphs/App.swift
- Define HieroglyphsApp struct conforming to App
- Use @main attribute
- Define Window scene (not WindowGroup) for single-window macOS behavior
- Set window title to "Hieroglyphs"
- Window content is MainWindow()

**Done when:** App.swift exists and references MainWindow (which will be created next).

---

## S004: Write MainWindow.swift

**Intent:** Create the empty three-column NavigationSplitView that defines the app's layout.

**Work:**
- Create Sources/Hieroglyphs/Views/MainWindow.swift
- Define MainWindow struct conforming to View
- Body is NavigationSplitView with three columns:
  - Sidebar column: Text("Sidebar") placeholder
  - Content column: Text("List") placeholder
  - Detail column: Text("Detail") placeholder
- Use preferredCompactColumn binding with @State (pattern from TakeNote)

**Done when:** MainWindow.swift exists with three-column layout.

---

## S005: Write Info.plist

**Intent:** Provide app metadata required by macOS.

**Work:**
- Create Resources/Info.plist
- Include CFBundleName: "Hieroglyphs"
- Include CFBundleIdentifier: "com.adamrdrew.hieroglyphs"
- Include CFBundleVersion: "0.1.0"
- Include CFBundleShortVersionString: "0.1.0"
- Include LSMinimumSystemVersion: "26.0"

**Done when:** Info.plist exists with all required fields.

---

## S006: Write build script

**Intent:** Provide a command-line script to build the .app bundle.

**Work:**
- Create Scripts/build-app.sh
- Script runs `swift build -c release`
- Make script executable (chmod +x)
- Add shebang (#!/usr/bin/env bash)
- Add comments explaining purpose

**Done when:** Scripts/build-app.sh exists, is executable, and successfully runs `swift build`.

---

## S007: Write CLAUDE.md

**Intent:** Document collaboration patterns for AI assistants working on this codebase.

**Work:**
- Create CLAUDE.md at repository root
- Include project overview (what Hieroglyphs is)
- Include collaboration guidelines:
  - Always consult .ushabti/laws.md and .ushabti/style.md
  - Follow Ushabti phase workflow (Scribe → Builder → Overseer)
  - Reference .ushabti/docs/ for system understanding
  - Respect agent role boundaries
- Include command reminders (swift build, swift run, swift test)
- Note that this is an SPM package, not an Xcode project

**Done when:** CLAUDE.md exists at repository root with comprehensive collaboration guidance.

---

## S008: Verify build and launch

**Intent:** Confirm that the skeleton project builds and launches successfully.

**Work:**
- Run `swift build` from repository root
- Verify build completes with no errors
- Run `swift run` from repository root
- Verify that a macOS window appears with three columns showing placeholder text
- Verify no console errors or warnings
- Verify window can be closed cleanly

**Done when:** `swift build` and `swift run` both succeed, and the app launches with the expected three-column layout.
