# Claude Collaboration Guide for Hieroglyphs

## Project Overview

Hieroglyphs is a macOS-native markdown-based project management tool built with SwiftUI and Swift Package Manager. The app manages structured markdown files with YAML frontmatter, enabling transparent, version-controlled project workflows that integrate seamlessly with AI assistants, command-line tools, and text editors.

### Core Design Principles

- **Filesystem as source of truth:** All data lives in plain text markdown files. No databases, no hidden state.
- **AI-first workflows:** External edits by LLMs and tools are first-class, not edge cases.
- **macOS leverage:** Uses Spotlight for search, FSEvents for file watching, extended attributes for tags.
- **Design consistency with TakeNote:** Three-column NavigationSplitView, click-to-edit markdown, SF Symbols.

## Development Workflow: Ushabti

Hieroglyphs is built using the Ushabti framework. Ushabti is a phase-based, agent-driven workflow system. Work is organized into phases, each phase has a plan, implementation steps, and review. Three agents manage the workflow:

1. **Ushabti Scribe** — Plans phases. Writes `phase.md`, `steps.md`, and scaffolds `progress.yaml`.
2. **Ushabti Builder** — Implements phases. Executes steps in order, updates `progress.yaml`, marks steps implemented.
3. **Ushabti Overseer** — Reviews phases. Verifies correctness, updates `review.md`, marks phases GREEN or YELLOW/RED.

**Agent role boundaries are strict.** Builder does not plan. Scribe does not implement. Overseer does not fix code.

### Required Reading Before Acting

Before starting any work, agents **must** read:

- **`.ushabti/laws.md`** — Non-negotiable project constraints (L01-L16). Laws are absolute.
- **`.ushabti/style.md`** — Code conventions, patterns, and quality standards. Style is binding.
- **`.ushabti/docs/`** — System documentation. Scribe consults before planning. Builder consults before implementing. Overseer verifies docs are reconciled after changes.
- **Phase files** — `phase.md`, `steps.md`, `progress.yaml` (and `review.md` for Overseer).

### Phase Workflow

Phases live in `.ushabti/phases/NNNN-slug/`. Each phase directory contains:

- **`phase.md`** — Intent, scope, constraints, acceptance criteria.
- **`steps.md`** — Ordered implementation steps with intent, work, and done-when conditions.
- **`progress.yaml`** — Step tracking. Builder marks `implemented: true`. Overseer marks `reviewed: true`.
- **`review.md`** — Overseer's findings and verdict (GREEN, YELLOW, or RED).

**Phases must be worked in order.** Do not skip steps. Do not improvise. If a step is unclear or insufficient, add a new step to `steps.md` and update `progress.yaml` accordingly.

### Command-Line Operations

Hieroglyphs is an SPM package. Build, run, and test from the command line:

```bash
swift build          # Build the project
swift run            # Run the app
swift test           # Run tests
./Scripts/build-app.sh  # Build release configuration
```

**No Xcode project files.** The repository must remain free of `.xcodeproj` or `.xcworkspace` files.

## Laws and Style

### Laws (Non-Negotiable)

- **L01:** Filesystem is the single source of truth. No databases.
- **L02:** Opinionated on write, laissez-faire on read. Preserve unknown frontmatter fields.
- **L03:** No Xcode project. SPM only.
- **L04:** No SwiftData, Core Data, or SQLite.
- **L05:** External changes are first-class. File watching is mandatory.
- **L06:** Platform leverage over reinvention. Use Spotlight, FSEvents, Trash, extended attributes.
- **L07:** macOS 26 only. No cross-platform code.
- **L08:** Frontmatter is tag source of truth. Project to extended attributes, never the reverse.
- **L09:** Sandi Metz principles. Protocol-based services, plain data models, dependency injection.
- **L10:** Design language consistency with TakeNote.
- **L11:** Test coverage for all public APIs. Tests and lint must pass.
- **L12:** No dead code. No unused symbols, no commented-out code blocks.
- **L13-L16:** Docs consultation and maintenance by Scribe, Builder, and Overseer.

### Style (Binding Conventions)

- **Sandi Metz's Rules:** Small classes (100 lines), short methods (5 lines), limited parameters (4 max). Follow the spirit with judgment.
- **SOLID principles:** Single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion.
- **No regex.** Absolutely banned. Use string methods and parsers.
- **Naming:** Clarity over brevity. No single-letter variables except reluctant `i` in iterators.
- **Composition over inheritance.** Favor protocols and injection over deep hierarchies.
- **Layer architecture:**
  - **Models:** Plain Swift structs/enums with no dependencies.
  - **Services:** Protocol-based, handle all side effects.
  - **Views:** Small, composable SwiftUI views organized by feature.
  - **Utilities:** Pure functions with no side effects.
  - **ViewModel:** Single shared coordinator injected via @Environment.

## Working with Hieroglyphs

### File Structure

The workspace directory contains:

- **`projects/`** — Project folders with `card.md`, `cards/`, and `.cards/` subdirectories.
- **Cards** — Markdown files with YAML frontmatter defining title, type, status, priority, tags, etc.

Every project and card has a unique slug identifier. File paths and frontmatter slugs must stay synchronized.

### Development Patterns

- **Three-column NavigationSplitView:** Sidebar (projects) | List (cards) | Detail (card editor).
- **Click-to-edit markdown:** ZStack with Markdown preview and CodeEditor. Tap to edit, Escape to preview.
- **Searchable UI:** `.searchable()` modifier backed by Spotlight (NSMetadataQuery).
- **File watching:** FSEvents to detect external changes in real time.
- **Tag reconciliation:** Frontmatter tags project one-way to macOS extended attributes.

### Testing

- Every public method has tests.
- Tests cover all execution paths through public APIs.
- Services tested against protocol interfaces with mocks.
- Views are not unit tested (SwiftUI views lack meaningful testable API).

Tests and lint must pass before Overseer marks a phase GREEN.

## Reminders for AI Assistants

1. **Always consult laws and style** before writing code.
2. **Follow the Ushabti workflow.** Respect agent role boundaries.
3. **Read `.ushabti/docs/` for system understanding.** Keep docs synchronized with code changes.
4. **Do not improvise.** If a step is unclear, add a new step. If a law conflicts with a plan, stop and report it.
5. **Measure twice, cut once.** Correctness over speed.
6. **No Xcode.** This is an SPM package. Build and run from the command line.
7. **Filesystem is truth.** All state must reconstruct from disk.

When in doubt, ask. When the plan is insufficient, extend it. When a law is violated, stop.

---

> Stone set true. Work measured carefully. Foundations built to last.
