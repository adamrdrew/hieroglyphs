# Project Laws

## Preamble

These laws define the non-negotiable invariants for Hieroglyphs. Every phase, implementation, and refactor must comply with these constraints. Overseer MUST verify compliance before marking any phase GREEN. Laws are binding across the entire project lifecycle.

## Laws

### L01 — Filesystem as Source of Truth

- **Rule:** The app MUST NOT maintain any state that diverges from what is on disk. All data MUST live in the workspace directory as plain text files. There MUST be no database, no cache serving as primary storage, and no cloud service. If in-memory state and filesystem disagree, the filesystem MUST win.
- **Rationale:** Hieroglyphs is designed to be transparent, inspectable, and tool-agnostic. The filesystem is the single source of truth to enable interoperability with LLMs, editors, and command-line tools.
- **Enforcement:** Verify that no persistence mechanism exists other than file I/O. Verify that on conflict, the app always defers to filesystem state. Check that all state reconstruction is possible from files alone.
- **Scope:** Entire application
- **Exceptions:** None

### L02 — Opinionated on Write, Laissez-Faire on Read

- **Rule:** The app MUST offer predefined options in UI for structured fields (status, type, priority). The app MUST display whatever it finds in frontmatter without validation, complaint, or data loss. Unknown fields MUST be preserved when writing back to a file. The app MUST NOT reject any file it cannot fully parse — it MUST do its best to handle it.
- **Rationale:** Users and external tools may extend frontmatter beyond what the UI exposes. The app must be a good citizen that preserves user data even when it doesn't understand all of it.
- **Enforcement:** Verify that unknown frontmatter fields round-trip unchanged. Verify that the app does not throw errors or refuse to load malformed files. Verify that UI constrains writes to valid options but displays raw values on read.
- **Scope:** All file I/O and UI input components
- **Exceptions:** None

### L03 — No Xcode Project

- **Rule:** The codebase MUST be a Swift Package Manager package. There MUST be no `.xcodeproj`, `.xcworkspace`, or any Xcode-managed project files. The project MUST build with `swift build`, run with `swift run`, and test with `swift test` from the command line.
- **Rationale:** Xcode project files are opaque, merge-hostile, and IDE-coupled. SPM is declarative, version-control-friendly, and CLI-first.
- **Enforcement:** Verify that no `.xcodeproj` or `.xcworkspace` exists in the repository. Verify that `swift build`, `swift run`, and `swift test` succeed without requiring Xcode.
- **Scope:** Entire repository
- **Exceptions:** None

### L04 — No SwiftData

- **Rule:** Data persistence MUST be handled entirely through the filesystem. SwiftData, Core Data, SQLite, and any other database or ORM framework are FORBIDDEN. Models MUST be plain Swift types, not database entities.
- **Rationale:** Databases introduce hidden state, schema migrations, and opacity. Hieroglyphs commits to filesystem transparency.
- **Enforcement:** Verify that no `import SwiftData`, `import CoreData`, or SQLite libraries appear in the codebase. Verify that models are plain structs/classes with no persistence framework annotations.
- **Scope:** Entire codebase
- **Exceptions:** None

### L05 — External Changes Are First-Class

- **Rule:** The app MUST NOT assume it is the only writer to the workspace. Changes made by LLMs, text editors, terminal commands, or any other external tool MUST be detected and reflected in the UI. This is NOT an edge case — it is a core design requirement.
- **Rationale:** Hieroglyphs is designed to integrate with AI workflows and developer tools. Multi-writer scenarios are the norm, not the exception.
- **Enforcement:** Verify that file-watching mechanisms (e.g., FSEvents) are in place. Verify that external edits are reflected in the UI without requiring manual refresh. Test by editing files externally and confirming UI updates.
- **Scope:** All file monitoring and UI refresh logic
- **Exceptions:** None

### L06 — Platform Leverage Over Reinvention

- **Rule:** When macOS provides a system capability that serves our needs, we MUST use it. Examples include Spotlight for search, extended attributes for tags, FSEvents for file watching, and Trash for deletion. We MUST NOT build custom implementations of things the OS already provides.
- **Rationale:** macOS has battle-tested, optimized, and accessible system services. Reinventing them wastes effort and produces inferior results.
- **Enforcement:** Verify that Spotlight APIs (NSMetadataQuery or similar) are used for search. Verify that extended attributes are used for tags. Verify that FSEvents is used for file monitoring. Verify that file deletion uses system Trash APIs.
- **Scope:** All platform integration points
- **Exceptions:** None

### L07 — macOS Only

- **Rule:** The app MUST target macOS 26 (Tahoe) exclusively. There MUST be no cross-platform conditionals, no iOS/iPadOS/visionOS code paths, and no abstraction layers introduced for hypothetical future platform support.
- **Rationale:** Cross-platform abstraction dilutes focus and introduces complexity. Hieroglyphs is a macOS-first tool that leverages macOS-specific capabilities.
- **Enforcement:** Verify that Package.swift specifies only macOS platform. Verify that no `#if os(iOS)` or similar conditionals exist. Verify that code uses macOS-specific APIs without abstraction layers.
- **Scope:** Entire codebase
- **Exceptions:** None

### L08 — Frontmatter Is Tag Source of Truth

- **Rule:** Tags MUST live in YAML frontmatter. Tags MUST be projected one-way from frontmatter to macOS extended file attributes (`com.apple.metadata:_kMDItemUserTags`). The reverse direction MUST NEVER occur. If Finder tags and frontmatter tags disagree, frontmatter MUST win and the reconciler MUST overwrite the file metadata.
- **Rationale:** Frontmatter is version-controlled, transparent, and portable. Extended attributes are opaque and can be lost on file copy. Frontmatter is the authoritative source.
- **Enforcement:** Verify that tags are read from frontmatter, not extended attributes. Verify that a reconciliation process writes from frontmatter to extended attributes. Verify that no code path reads extended attributes and writes them back to frontmatter.
- **Scope:** All tag reading, writing, and synchronization logic
- **Exceptions:** None

### L09 — Sandi Metz Principles

- **Rule:** Code MUST follow Sandi Metz's principles of object-oriented design:
  - Small classes and methods with single responsibilities
  - Depend on abstractions (protocols), not concretions
  - Open for extension, closed for modification
  - Composition over inheritance
  - Services MUST be protocol-based for testability
  - Models MUST be plain data types that do not know about persistence or UI
- **Rationale:** These principles produce maintainable, testable, and flexible code. They are well-established industry standards for quality.
- **Enforcement:** Verify that services are defined as protocols. Verify that models are plain structs/classes with no framework imports. Verify that classes have focused responsibilities. Verify that dependencies are injected as protocols, not concrete types.
- **Scope:** Entire codebase
- **Exceptions:** None

### L10 — Design Language Consistency with TakeNote

- **Rule:** Hieroglyphs MUST look and feel like it came from the same developer as TakeNote. Shared patterns include: three-column NavigationSplitView, click-to-edit markdown (CodeEditorView + swift-markdown-ui), SF Symbols for icons, and consistent spacing and layout conventions. Refer to `takenote-study-notes.md` for specifics.
- **Rationale:** Consistent design language reduces cognitive load for users and establishes a recognizable visual identity.
- **Enforcement:** Verify that the app uses a three-column NavigationSplitView. Verify that markdown editing uses CodeEditorView and swift-markdown-ui. Verify that icons are SF Symbols. Compare spacing, fonts, and layout to TakeNote patterns documented in `takenote-study-notes.md`.
- **Scope:** All UI code
- **Exceptions:** None

### L11 — Test Coverage

- **Rule:** Every public API method MUST have tests. Tests MUST cover all execution paths through public methods. Private methods are implicitly tested through the public API. Tests and lint MUST pass for every phase in order for the Overseer to mark it GREEN. A phase with failing tests or lint violations is INVALID.
- **Rationale:** Tests are the safety net that enables refactoring and prevents regressions. Public API coverage ensures that all user-facing behavior is verified.
- **Enforcement:** Verify that every public method in every module has at least one test. Run tests with coverage reporting. Verify that lint passes. Do not mark a phase GREEN if tests fail or lint violations exist.
- **Scope:** Entire codebase
- **Exceptions:** None

### L12 — No Dead Code

- **Rule:** No symbol may exist without references. Unused types, methods, properties, imports, and variables MUST be removed. Dead code MUST NOT be commented out and left behind — it MUST be deleted. Version control is the archive, not comments.
- **Rationale:** Dead code creates confusion, increases maintenance burden, and obscures intent. Git preserves history; there is no need to keep unused code in the working tree.
- **Enforcement:** Use linting tools to detect unused symbols. Verify that no commented-out code blocks exist. Verify that all imports are used.
- **Scope:** Entire codebase
- **Exceptions:** None

### L13 — Scribe Docs Consultation

- **Rule:** Scribe MUST consult `.ushabti/docs` to inform Phase planning. Understanding documented systems is prerequisite to coherent planning.
- **Rationale:** Documented knowledge of existing systems prevents redundant or conflicting planning. Scribe must ground plans in current project state.
- **Enforcement:** Verify that Scribe reads `.ushabti/docs` before writing phase plans. Check that phase plans reference or acknowledge existing documented architecture.
- **Scope:** Scribe agent, Phase planning workflow
- **Exceptions:** None

### L14 — Builder Docs Usage and Maintenance

- **Rule:** Builder MUST consult `.ushabti/docs` during implementation and MUST update docs when code changes affect documented systems. Docs are both a resource and a maintenance responsibility.
- **Rationale:** Docs inform implementation and must remain accurate as code evolves. Builder is responsible for keeping docs synchronized with code changes.
- **Enforcement:** Verify that Builder reads `.ushabti/docs` before implementation. Verify that docs are updated when code changes affect documented systems. Check that Builder marks steps as requiring doc updates in progress tracking.
- **Scope:** Builder agent, implementation workflow
- **Exceptions:** None

### L15 — Overseer Docs Reconciliation

- **Rule:** Overseer MUST verify that docs are reconciled with code changes before declaring a Phase complete. Stale docs are defects.
- **Rationale:** A Phase is not complete if its documentation is out of sync with its code. Overseer is the gatekeeper for Phase completion.
- **Enforcement:** Verify that Overseer checks for doc updates in review. Verify that review.md includes a docs reconciliation section. Do not mark a phase GREEN if docs are stale.
- **Scope:** Overseer agent, review workflow
- **Exceptions:** None

### L16 — Phase Completion Requires Docs Reconciliation

- **Rule:** A Phase cannot be marked GREEN/complete until docs are reconciled with the code work performed during that Phase.
- **Rationale:** Completeness includes documentation. A Phase with unreconciled docs is incomplete by definition.
- **Enforcement:** Verify that Overseer blocks GREEN status if docs are not reconciled. Verify that progress.yaml includes doc reconciliation as a completion criterion.
- **Scope:** All phases, Overseer review process
- **Exceptions:** None

### L17 — UI State Correctness

- **Rule:** Views MUST always reflect current application state. When context changes — project selection, navigation, tab switching — all affected views MUST update to reflect the new context immediately. Views MUST NOT display stale content from a previous selection. Async operations MUST provide visual feedback (progress indication) and MUST surface errors visibly. Timer-driven or polling-driven views MUST NOT trigger redraws when content has not changed.
- **Rationale:** Hieroglyphs is a GUI application. Code that compiles, passes tests, and follows SOLID principles can still produce a broken user experience. Stale views, missing loading states, silent failures, and unnecessary redraws are defects — they erode user trust and make the app feel unreliable. UI state correctness is not cosmetic; it is functional correctness.
- **Enforcement:** Verify that views bound to a selection reset when that selection changes (via `.id()`, `onChange(of:)`, or equivalent). Verify that async operations show a `ProgressView` or equivalent while in progress and an alert or visible error on failure. Verify that polling-driven views compare content before triggering updates (content hash, equality check, or count comparison). Verify that modals and sheets have constrained dimensions — content scrolls, the container does not grow unboundedly.
- **Scope:** All UI code
- **Exceptions:** None

### L18 — Design Is How It Works

- **Rule:** The app MUST look and behave like a native macOS 26 application built by someone who cares. Every interactive element MUST communicate its state: if it cannot be activated, it MUST be disabled or hidden. If an operation is in progress, the user MUST be told. If something succeeded or failed, the user MUST know. Controls MUST use platform-native appearance. The app MUST use system colours, system fonts, system materials, and standard macOS controls. Custom visual treatments are permitted only when no system equivalent exists. The app MUST adopt the macOS 26 Liquid Glass design language: standard controls receive glass treatment automatically; custom navigation chrome MUST use `.glassEffect()`. The visual layer exists to communicate — not to decorate.
- **Rationale:** "Design is not just what it looks like and feels like. Design is how it works." A button that looks clickable but does nothing is a lie. A spinner that never resolves is abandonment. A custom control that behaves differently from its system equivalent is a trap. Functional clarity IS the aesthetic. Polish is not a finishing step applied after the real work — it is the real work. macOS 26 introduced Liquid Glass as the defining design language — apps that ignore it look dated immediately.
- **Enforcement:** Verify that disabled controls are visually disabled (`.disabled(true)` or hidden). Verify that loading states show progress indication. Verify that success/failure is communicated to the user. Verify that no hardcoded colours exist where system colours would serve. Verify that standard SwiftUI controls are used (Toggle, Picker, Button, TextField) rather than custom implementations of the same affordance. Verify that the app respects dark mode, accent colour, and system font size without special-casing. Verify that custom `.toolbarBackground()` overrides have been removed (let system glass apply). Verify that `.tabItem()` is not used (deprecated — use `Tab` struct). Verify that glass is applied only to navigation-layer elements, never to content.
- **Scope:** All UI code
- **Exceptions:** None
