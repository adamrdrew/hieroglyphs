# Phase 0001: Project Skeleton

## Intent

Establish a buildable Swift Package Manager project with an empty three-column NavigationSplitView window that serves as the foundation for Hieroglyphs. This phase creates the minimal viable structure required for all future development work.

This is the bootstrap phase. It provides a green build, a launchable app window, and the directory structure that all subsequent phases will build upon.

## Scope

**In scope:**
- Package.swift with macOS 26 platform and dependencies (CodeEditorView, swift-markdown-ui)
- App.swift entry point with @main and Window scene
- MainWindow.swift with empty three-column NavigationSplitView
- Directory structure: Sources/Hieroglyphs/{Models/, Services/, Views/, Utilities/}
- Resources/Info.plist with app metadata
- Scripts/build-app.sh for building the .app bundle
- CLAUDE.md at repository root documenting AI collaboration patterns

**Out of scope:**
- Any business logic, models, or services
- File watching, workspace loading, or data persistence
- Meaningful UI beyond the empty three-column layout
- Tests (no testable logic exists yet)

## Constraints

**Laws:**
- L03 — No Xcode Project: Must be SPM-only, buildable via `swift build`
- L07 — macOS Only: Target macOS 26 (Tahoe) exclusively
- L09 — Sandi Metz Principles: When services are introduced later, they will be protocol-based
- L10 — Design Language Consistency with TakeNote: Use three-column NavigationSplitView pattern

**Style:**
- Project structure per style guide: Sources/Hieroglyphs with subdirectories
- Window (not WindowGroup) for single-window macOS behavior
- SF Symbols for icons (none needed in this phase, but pattern established)

## Acceptance Criteria

1. `swift build` completes successfully from repository root
2. `swift run` launches a macOS window displaying three empty columns
3. Package.swift specifies macOS 26 platform minimum
4. Package.swift includes dependencies: CodeEditorView (mchakravarty/CodeEditorView) and swift-markdown-ui (gonzalezreal/swift-markdown-ui)
5. Directory structure exists: Sources/Hieroglyphs/{Models/, Services/, Views/, Utilities/}
6. Resources/Info.plist exists with CFBundleName, CFBundleIdentifier, CFBundleVersion
7. Scripts/build-app.sh exists and can execute to produce a .app bundle
8. CLAUDE.md exists at repository root with collaboration documentation
9. App launches without crashes or errors in console

## Risks / Notes

**Intentionally minimal:** This phase contains no business logic. It is purely structural. The goal is a buildable, launchable foundation. All meaningful functionality is deferred to later phases.

**Build script is simple:** Scripts/build-app.sh will be a straightforward wrapper around `swift build`. Fancy packaging (icons, notarization) is post-v1.

**Info.plist minimal:** We include only the fields required for a functioning app. Extended metadata (credits, app category, document types) deferred.

**CLAUDE.md authorship:** CLAUDE.md documents patterns for working with LLMs on this codebase. It is a living document that will evolve as the project grows, but this phase establishes the initial version.
