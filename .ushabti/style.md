# Project Style Guide

## Purpose

This style guide defines how we build Hieroglyphs. Unlike laws, which are invariant constraints, style governs conventions, patterns, and expectations that promote consistency and maintainability. Style may evolve over time, but make no mistake: this is not a loose set of suggestions. This is how we write code.

Builder implements according to style. Overseer reviews against style. When in doubt, favor the spirit of these principles over literal interpretation.

---

## The Church of Object-Oriented Design

We are OOP fundamentalists. Our patron saint is Sandi Metz. We write code she would approve of. Every design decision should be filtered through her principles. If you are about to write something and you think Sandi would wince, stop and redesign.

### Sandi Metz's Rules

These are guiding principles enforced with judgment, not hard cutoffs. A 105-line class may be acceptable. A 125-line class might be acceptable. Builder should aim to honor these rules. Overseer should review with good judgment.

1. Classes should be no longer than 100 lines of code.
2. Methods should be no longer than 5 lines of code.
3. Pass no more than 4 parameters to a method.
4. Break these rules only when you can articulate exactly why and the tradeoff is worthwhile.

### SOLID Principles

- **Single Responsibility Principle:** A class has one, and only one, reason to change. If you are describing what a class does and you use the word "and", it does too much.
- **Open/Closed Principle:** Classes are open for extension, closed for modification. When requirements change, you add new code. You do not edit existing code.
- **Liskov Substitution:** Any subclass must be substitutable for its superclass without breaking behavior. If you override a method to raise an error, your design is wrong.
- **Interface Segregation:** Many small, specific protocols are better than one large general-purpose protocol. Depend only on what you use.
- **Dependency Inversion:** Depend on abstractions (protocols), not concretions. High-level modules must not depend on low-level modules. Both depend on abstractions.

### Additional Metz Principles

- **Depend on behavior, not data.** Objects send messages to each other. They do not reach into each other's internals. Wrap instance variables in methods.
- **Law of Demeter.** Only talk to your immediate neighbors. No train wrecks (object.thing.other.stuff). If you are chaining dots, you are coupling to structure. Delegate instead.
- **Duck typing.** It is not what an object IS that matters, it is what it DOES. Use protocols (duck types) to define roles. Send messages to roles, not classes.
- **Composition over inheritance.** Favor composing objects from small, focused pieces over deep inheritance hierarchies. Use protocols and injection.
- **Isolate dependencies.** When you must depend on something you do not control, wrap it. Isolate external dependencies behind your own interfaces.
- **Design for change.** Every design decision should make future change easier. Concrete code is easy to understand but costly to extend. Abstract code may seem obscure at first but is far easier to change.

---

## Code Is a Human Interface

Computers do not need code. Computers need machine instructions. Code exists for humans and LLMs to read, understand, and modify. Every line we write should be optimized for the reader, not the machine.

### Naming

- Names must say what something does and do what they are named.
- Longer names are fine. Clarity always beats brevity.
- Single letter variables are banned, with one reluctant exception: `i` in an iterator. Even there, prefer descriptive names when clarity benefits. Never use `x`, `y`, `z` as standalone variables. Use `thingX`, `thingY`, `thingZ` or structure them as properties (`thing.x`, `thing.y`, `thing.z`).
- Boolean names read as questions: `isLoading`, `hasCards`, `canDeleteProject`.
- Method names describe the action: `parsesFrontmatter`, `writesCardToDisk`, `reconcilesTags`.
- Type names are nouns: `Card`, `Project`, `WorkspaceService`.
- Avoid abbreviations unless universally understood (URL, ID, HTTP are fine; mgr, ctx, val are not).

### Readability

- Always use the simplest syntax that communicates intent.
- String operations use string methods, not regex. **Regex is banned.** Absolutely. No exceptions. No softening. No "but what if". Regex is evil. If you think you need regex, you need a better parser or a different approach.
- Prefer explicit over clever. No code golf. No one-liners that require 30 seconds of squinting.
- Ternary expressions are acceptable for simple value selection. If either branch has side effects or is more than a simple expression, use if/else.
- Comments explain WHY, never WHAT. If the code needs a comment explaining what it does, the code is not clear enough. Rename things until the comment is unnecessary.

### Conditionality

Limit conditional logic. Use smart patterns to provide behavior variation at runtime WITHOUT if statements where possible:

- **Protocol conformance / duck typing.** Different behavior comes from different types conforming to the same protocol, not from switching on a type field.
- **Strategy pattern.** Inject behavior rather than branching on configuration.
- **Polymorphism over conditionals.** If you have a switch/case on a type enum that dispatches different behavior, you probably need a protocol and conforming types.
- **Map lookups over if/else chains.** When mapping values, use dictionaries.
- **Guard clauses for early returns.** When you must use conditionals, prefer guard for precondition checks. Keep the happy path unindented.

If statements are not evil. But if you have more than two branches, or nested ifs, it is a design smell. Step back and find the abstraction.

---

## Project Structure

### Directory Layout

```
Hieroglyphs/
  Package.swift
  Sources/
    Hieroglyphs/
      App.swift
      Models/
      Services/
      Views/
      Utilities/
  Tests/
    HieroglyphsTests/
  Scripts/
    build-app.sh
  Resources/
    Info.plist
    AppIcon.icns
```

### File Conventions

- One primary public type per file.
- File name matches the primary type name.
- Views: PascalCase (`CardListEntry.swift`)
- Models: PascalCase (`Card.swift`, `Project.swift`)
- Services: PascalCase with Service suffix (`WorkspaceService.swift`)
- Protocols: PascalCase describing capability (`FileWatching.swift`, `SearchProviding.swift`)
- Utilities: PascalCase describing function (`FrontmatterParser.swift`)

---

## Layer Architecture

### Models (Sources/Hieroglyphs/Models/)

Plain Swift structs and enums. Zero dependencies on Services, Views, or frameworks beyond Foundation. Models are data containers with computed properties and simple transformations. They do not perform I/O. They do not know they will be displayed. They do not know they came from a file.

### Services (Sources/Hieroglyphs/Services/)

Protocol-based types that handle all side effects. Every service has a protocol defining its public interface and a concrete implementation. Services are injected via SwiftUI Environment. Test with mock implementations against the protocol.

### Views (Sources/Hieroglyphs/Views/)

Small, composable SwiftUI views. Each view does one thing. Organized by feature:

- Views/MainWindow/
- Views/Sidebar/
- Views/CardList/
- Views/CardDetail/
- Views/Shared/

Views observe a shared ViewModel via @Environment. They do not call services directly.

### Utilities (Sources/Hieroglyphs/Utilities/)

Pure functions with no side effects. Given the same input, they always produce the same output. Examples: `FrontmatterParser`, `SlugGenerator`, `DateFormatting`.

### ViewModel (HieroglyphsVM)

Single shared ViewModel holding selection state, sort/filter preferences, navigation state. Coordinates between services. Injected at the app level.

---

## SwiftUI Patterns

### Navigation

Three-column NavigationSplitView following TakeNote's pattern.

Reference materials:
- `/Users/adam/Claude Projects/Hieroglyphs/takenote-study-notes.md`
- `/Users/adam/Library/Mobile Documents/com~apple~CloudDocs/Xcode Projects/TakeNote`

### Markdown Editing

Click-to-edit from TakeNote: ZStack with Markdown() preview and CodeEditor() in edit mode. Tap to edit, Escape to preview.

### Search

.searchable() backed by Spotlight via NSMetadataQuery.

### Icons

SF Symbols exclusively. Monochrome, hierarchical rendering. Color used sparingly for semantic meaning (status, priority).

---

## SwiftUI UX Patterns

This section defines behavioural patterns for SwiftUI views. Code correctness alone is not sufficient — views must behave correctly from the user's perspective. These patterns are as important as SOLID principles. Overseer reviews against these patterns. Builder implements according to them.

### Navigation State Reset

When the user changes context — selecting a different project, switching tabs, navigating to a different item — all views that depend on that context MUST update immediately. Stale content from a previous selection is a defect.

**Patterns:**
- Use `.id(selectedProject?.id)` on navigation destination views to force SwiftUI to rebuild them when the selection changes. This is the primary mechanism — it destroys and recreates the view, ensuring no stale state survives.
- Use `onChange(of: selectedProject)` to explicitly clear local `@State` properties when the parent context changes (e.g., clear a selected card when the project changes, clear scroll position, reset disclosure states).
- When a view depends on a parent selection, ensure it handles `nil` gracefully — show an empty state, not a stale previous state.

**Anti-patterns:**
- Views that read from a parent binding but have local `@State` that does not reset on context change. SwiftUI preserves `@State` across recompositions unless the view identity changes.
- Navigation destinations that appear correct because the data binding updates, but local UI state (scroll position, expanded sections, edit mode, text field content) is left over from the previous item.

### Async Operation Feedback

Any user-initiated operation that does not complete within a single frame MUST provide visual feedback. The user must always know: (1) something is happening, (2) when it finishes, and (3) if it failed.

**Patterns:**
- Model async operations as an explicit state: `.idle`, `.loading`, `.loaded(result)`, `.failed(error)`. The view switches on this state.
- While loading: show a `ProgressView` with a brief description. Hide or disable the triggering control so the user cannot double-fire.
- On failure: show the error visibly — an `.alert()`, a banner in the view, or an inline error message. Never fail silently.
- On success: transition to the loaded state. If the operation changes navigation or selection, update accordingly.

**Anti-patterns:**
- Firing an async operation and leaving the UI unchanged until it completes. The user clicks a button, nothing happens for 2 seconds, then the UI suddenly changes.
- Catching errors in a `try?` or `catch {}` block without surfacing them. Silent failures are the worst UX defect — the user does not know whether the operation succeeded, failed, or is still in progress.

### Polling and Live Data

Views driven by timers or file-watching MUST be efficient. Unnecessary redraws degrade the entire app, not just the affected view.

**Patterns:**
- Before updating `@State` or `@Published` properties from polled data, compare the new data to the existing data. Only assign if the content has actually changed. SwiftUI triggers a view update on every `@State` assignment, even if the value is identical — use an explicit equality check before assigning.
- For list data (e.g., event streams), prefer appending new items rather than replacing the entire array. Maintain stable `Identifiable` IDs so SwiftUI can diff incrementally.
- Preserve user-controlled UI state across data refreshes: scroll position, expanded disclosure groups, text field content. The data layer updates; the interaction state does not reset.
- Use content hashing or a simple count/timestamp comparison as a cheap guard before doing expensive parsing or array replacement.

**Anti-patterns:**
- Assigning `self.events = newEvents` on every timer tick regardless of whether anything changed. This triggers a full view diff on every tick.
- Replacing the entire array when only one item was appended, causing SwiftUI to diff and re-render the entire list.
- Data refreshes that reset scroll position to the top or collapse disclosure groups the user had opened.

### Modal and Sheet Sizing

Modals, sheets, and popovers MUST have constrained dimensions. The container defines a maximum size; the content scrolls within it.

**Patterns:**
- Use `.frame(maxWidth:maxHeight:)` on the outer container of sheet/modal content.
- Wrap variable-length content (text editors, lists, previews) in a `ScrollView` inside the constrained frame.
- Text input areas that accept multi-line content (e.g., card body, notes) MUST use a `ScrollView` wrapping a `TextEditor`, with the `TextEditor` constrained by `maxHeight`. The `TextEditor` scrolls; the modal does not grow.

**Anti-patterns:**
- A `TextEditor` in a sheet with no height constraint — the sheet grows infinitely as the user types.
- A `List` or `ForEach` in a modal with no frame constraint — the modal height is determined by the number of items.

### Empty States

Views that can have zero items MUST display an intentional empty state. A blank area with no explanation is confusing.

**Patterns:**
- When a list or collection is empty, show a brief message explaining why and (if applicable) how to add content. Use secondary text styling and optionally an SF Symbol.
- Layout components (filter bars, toolbars, sort controls) that only make sense with content should either hide or visually collapse when the list is empty. A full-width filter bar above an empty list dominates the view and looks broken.
- Empty states should be visually light — they are placeholders, not features. A single line of `.secondary` text is usually sufficient.

**Anti-patterns:**
- A filter bar that expands to fill available space when the list below it is empty (SwiftUI spacer/flex behaviour can cause this when the list has zero height).
- A completely blank detail pane with no indication of what should be there or how to populate it.

---

## Visual Design & Interaction Quality

This section defines how the app looks, feels, and communicates. L18 establishes the law: design is how it works. This section tells you how to honour that law. These patterns are reviewed by the Overseer with the same rigour as code quality.

### Platform Nativeness

Hieroglyphs is a macOS app. It should be indistinguishable from a well-made first-party app in its use of system resources.

**Colours:**
- Use system semantic colours: `Color.primary`, `.secondary`, `Color.accentColor`, `Color(nsColor: .controlBackgroundColor)`, `Color(nsColor: .separatorColor)`.
- Never hardcode colour literals (e.g., `Color(red: 0.2, green: 0.4, blue: 0.6)`) for UI chrome. Hardcoded colours break dark mode, break accessibility, and fight the system.
- Semantic colour for status and priority (e.g., red for critical, green for done) is acceptable — but prefer SF Symbol colour rendering over background fills where possible.

**Materials, Vibrancy, and Liquid Glass:**
- Sidebars use `.sidebar` list style, which gets system vibrancy and Liquid Glass treatment automatically.
- Standard controls (toolbars, tab bars, search bars) receive Liquid Glass treatment automatically when built with Xcode 26. Do not fight this or override it.
- For custom navigation-layer chrome (floating panels, custom overlays), apply `.glassEffect(.regular)` explicitly. See the Liquid Glass section below for details.
- Traditional materials (`.ultraThinMaterial`, `.regularMaterial`) remain valid for content-layer translucent backgrounds — but glass is now the standard for navigation chrome.
- Remove any custom `.toolbarBackground()` overrides. They fight the system glass treatment.

**Dark Mode:**
- Automatic. If you use system colours, materials, and glass, dark mode works. If you have to write `if colorScheme == .dark`, something is wrong.

### Controls and Affordances

Every control communicates what it does and what state it is in. No ambiguity.

**Disabled states:**
- If a button cannot be pressed, apply `.disabled(true)`. SwiftUI dims it automatically. The user sees it exists but understands it is not available.
- If a control makes no sense in the current context (not just temporarily unavailable, but semantically irrelevant), hide it entirely. Do not show disabled controls that will never become enabled in that context.

**Loading states:**
- Already covered by L17 and the Async Operation Feedback patterns, but worth reiterating: the user must never be left wondering whether something is happening. A `ProgressView` with a brief label is always appropriate.

**Destructive actions:**
- Destructive actions (delete, remove, clear) use `.destructive` button role. SwiftUI renders them red. No custom styling needed.
- Destructive actions that cannot be undone MUST require confirmation. Use `.confirmationDialog()` or `.alert()`.

**Toolbar actions:**
- Use `.toolbar {}` with appropriate placement (`.primaryAction`, `.secondaryAction`, `.navigation`).
- Toolbar buttons use SF Symbols, not text labels, unless the action is ambiguous without a label.
- Group related actions using `ToolbarItemGroup`. Use `ToolbarSpacer(.fixed)` to visually separate groups within the toolbar.
- Use `.buttonStyle(.glass)` for standard toolbar buttons and `.buttonStyle(.glassProminent)` for primary/confirmation actions. SwiftUI applies `.glassProminent` automatically for `.confirmationAction` placement.
- Do not apply custom `.toolbarBackground()` — let the system Liquid Glass treatment apply naturally.

### Typography

Use system font styles exclusively. Let the platform handle sizing, weight, and Dynamic Type.

**Hierarchy (most to least prominent):**
- `.title`, `.title2`, `.title3` — section headings, view titles (use sparingly)
- `.headline` — list entry primary text, card titles in lists
- `.body` — default reading text, card body content, descriptions
- `.subheadline` — supporting information next to headlines
- `.caption`, `.caption2` — metadata, timestamps, secondary labels
- `.footnote` — supplementary detail, counts, status text

**Rules:**
- Never use `.font(.system(size: N))` to set an arbitrary point size. Use the semantic styles above.
- Use `.fontWeight()` to adjust emphasis within a style when needed, but prefer choosing the right semantic style first.
- Use `.foregroundStyle(.secondary)` or `.foregroundStyle(.tertiary)` to de-emphasise text rather than changing font size. Hierarchy comes from colour weight as much as size.

### SF Symbols

SF Symbols are the only icon system. No custom icons, no image assets for UI chrome.

**Rules:**
- Match symbol weight to surrounding text. If the label is `.body` (regular weight), the symbol should be regular weight. Use `.symbolVariant()` and `.fontWeight()` to match.
- Use `.symbolRenderingMode(.hierarchical)` as the default for toolbar and navigation symbols. It provides depth without requiring colour.
- Use `.symbolRenderingMode(.monochrome)` for inline symbols next to text (status indicators, list decorators).
- Use `.symbolRenderingMode(.multicolor)` sparingly — only where Apple provides meaningful multicolour variants (e.g., folder icons, warning signs).
- Consistent sizing within a context. All sidebar icons should be the same size. All toolbar icons should be the same size. Do not mix.

### Spacing and Layout

**Principles:**
- SwiftUI's default spacing is generally correct. Do not override it without reason.
- When you do override, use a consistent scale: 4, 8, 12, 16, 20, 24. No arbitrary values like 7 or 13.
- Padding within a container should be consistent on all sides unless there is a deliberate visual reason to vary it.

**macOS density:**
- macOS apps are denser than iOS apps. List rows should be compact enough to show many items without scrolling, but not so cramped that they are hard to scan or click.
- Do not add excessive vertical padding to list entries. The default SwiftUI list row height is usually right.
- Side-by-side information is good. macOS screens are wide. Use horizontal space rather than stacking everything vertically.

**Alignment:**
- Leading-align text. Do not centre-align body text or list content.
- Centre alignment is appropriate for empty states, placeholder messages, and single-line status indicators only.

### Information Hierarchy

Every view should have a clear visual hierarchy: the most important information is the most prominent, and supporting detail recedes.

**Patterns:**
- Primary content (card title, project name) uses `.headline` or `.body` with `.primary` colour.
- Secondary content (status, priority, dates) uses `.caption` or `.footnote` with `.secondary` colour.
- Tertiary content (IDs, file paths, technical metadata) uses `.caption2` with `.tertiary` colour, or is hidden behind a disclosure.
- Do not give equal visual weight to everything. A card list entry that shows title, status, priority, type, dates, and tags all at the same size and weight is unreadable. Pick 2–3 things to show prominently. The rest is supporting detail.

**Anti-patterns:**
- Flat lists where every piece of metadata has the same font size and colour. The eye has nowhere to land.
- Showing too much information by default. Progressive disclosure is a virtue — show the summary, let the user drill into the detail.

### macOS 26 Liquid Glass

macOS 26 introduced Liquid Glass as its defining design language. Hieroglyphs targets macOS 26 exclusively (L07) and MUST adopt it fully. This is not optional modernisation — it is the platform's visual identity.

**Core principle:** Glass is for the **navigation layer** — toolbars, tab bars, sidebars, floating action buttons, navigation chrome. Glass is NEVER for the **content layer** — list rows, cards, table cells, media containers.

**Automatic adoption:**
Standard SwiftUI components built with Xcode 26 receive glass treatment automatically. This includes:
- Toolbars and toolbar items
- Tab bars (when using the `Tab` struct)
- Sidebars in `NavigationSplitView`
- Search bars via `.searchable()`
- Segmented controls, toggles, sliders

For these, do nothing. The system handles it. Do not apply custom backgrounds or materials that would fight the automatic glass.

**Explicit glass for custom chrome:**
When building custom navigation-layer UI (floating panels, custom action bars, overlay controls), apply glass explicitly:

```swift
// Standard glass — use for most navigation chrome
customControl.glassEffect(.regular, in: .capsule)

// Clear glass — only over media-rich backgrounds where dimming is acceptable
overlay.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12))
```

**Tinting:**
Glass tint is for **semantic meaning only** — not decoration. A tinted glass element says "this is different from the others" (e.g., active filter, destructive action). Lower opacity tints often read better:

```swift
.glassEffect(.regular.tint(.blue.opacity(0.8)))
```

**Grouping with GlassEffectContainer:**
Glass cannot composite on top of other glass. When multiple glass elements sit near each other, wrap them in a `GlassEffectContainer`:

```swift
GlassEffectContainer(spacing: 40.0) {
    ForEach(actions) { action in
        ActionButton(action).glassEffect()
    }
}
```

**Morphing transitions with glassEffectID:**
When a glass element changes shape or position (e.g., compact ↔ expanded), use `glassEffectID` within a `GlassEffectContainer` and a shared `@Namespace` for smooth morphing:

```swift
@Namespace var ns

GlassEffectContainer {
    if isExpanded {
        ExpandedView().glassEffect().glassEffectID("panel", in: ns)
    } else {
        CompactView().glassEffect().glassEffectID("panel", in: ns)
    }
}
```

**Scroll edge effects:**
Control the visual treatment at scroll boundaries:

```swift
.scrollEdgeEffectStyle(.soft)   // Rounded, diffused edge — default for most content
.scrollEdgeEffectStyle(.hard)   // Sharp dividing line — for dense data views
```

**Tab bars:**
Use the `Tab` struct, not the deprecated `.tabItem()`:

```swift
TabView {
    Tab("Cards", systemImage: "rectangle.stack") { CardsView() }
    Tab("Plans", systemImage: "list.bullet.clipboard") { PlansView() }
    Tab("Search", systemImage: "magnifyingglass", role: .search) { SearchView() }
}
```

**Anti-patterns:**
- Applying `.glassEffect()` to content elements (list rows, card views, table cells). Glass is navigation, not content.
- Layering glass on glass. It does not composite correctly — use `GlassEffectContainer` to group.
- Adding `.blur()`, `.opacity()`, or `.background()` modifiers to glass views. These fight the glass rendering pipeline.
- Putting solid fills behind glass elements. Glass needs to see through to the content behind it.
- Using `.toolbarBackground()` to override the system glass treatment.
- Mixing `.regular` and `.clear` glass variants in the same visual group.
- Using tint for decorative purposes. Tint communicates meaning — active state, category, urgency.

**Reference:** Full API details and examples in `/Users/adam/Claude Projects/Alan/notes/liquid-glass-swiftui-reference.md`.

---

## Testing Strategy

- Every public method has tests.
- Tests cover all execution paths through public methods.
- Private methods are tested implicitly through public API.
- Models: unit tested (pure logic).
- Utilities: unit tested (pure functions).
- Services: tested against protocol interfaces with mock implementations.
- Views: not unit tested (SwiftUI views lack meaningful testable public API).
- Tests and lint must pass for every phase.

---

## Error Handling & Observability

The app does its best. It never crashes on malformed data.

- **File parse errors:** Show what we can, skip what we cannot.
- **Filesystem errors:** Log and surface in UI non-modally.
- **Missing files:** Treat as deleted, update UI accordingly.

---

## Performance & Resource Use

- Prefer lazy loading and incremental updates.
- Use FSEvents for file watching, not polling.
- Leverage macOS Spotlight for search indexing.
- Avoid unnecessary work: only recompute when inputs change.

---

## Git Conventions

- Main branch: `main`
- Commit messages: imperative mood, concise
- Each Ushabti phase is a logical unit of commits
- No force pushes to main

---

## Dependencies

Managed via SPM in Package.swift:

- **CodeEditorView** (mchakravarty/CodeEditorView) - markdown editor
- **swift-markdown-ui** (gonzalezreal/swift-markdown-ui) - markdown renderer
- **Yams** (jpsim/Yams) - YAML parsing (anticipated)

---

## Workspace Data Conventions

- Project folders: always slugified (`project-alpha`)
- Card folders: always slugified (`add-dark-mode`)
- Frontmatter fields: lowercase with hyphens where multi-word

---

## Review Checklist

When Overseer reviews a phase, verify:

### Code Quality
- [ ] All public methods have tests
- [ ] Tests and lint pass
- [ ] No dead code (unused imports, methods, types)
- [ ] No commented-out code
- [ ] No regex usage
- [ ] Single-letter variables limited to reluctant `i` in iterators
- [ ] Classes and methods honor Sandi Metz principles with good judgment
- [ ] Services are protocol-based
- [ ] Models are plain Swift types with no framework imports
- [ ] Dependencies are injected, not hardcoded
- [ ] Error handling follows "do your best" philosophy
- [ ] Code is optimized for human readability
- [ ] Documentation is reconciled with code changes

### UI State Correctness (L17)
- [ ] Views bound to a selection reset when that selection changes (`.id()` or `onChange(of:)`)
- [ ] Async operations show progress indication and surface errors visibly
- [ ] Timer/polling-driven views compare content before assigning to `@State`/`@Published`
- [ ] Modals and sheets have constrained dimensions — content scrolls, container does not grow
- [ ] Empty states are handled — no blank areas, no layout breakage on zero items
- [ ] User interaction state (scroll position, disclosure groups, edit mode) survives data refreshes

### Visual Design & Interaction Quality (L18)
- [ ] No hardcoded colour literals for UI chrome — system semantic colours only
- [ ] Dark mode works without any `colorScheme` conditionals
- [ ] Disabled controls are visually disabled (`.disabled(true)`) or hidden when irrelevant
- [ ] Destructive actions use `.destructive` role and require confirmation if irreversible
- [ ] Typography uses system semantic styles (`.headline`, `.body`, `.caption`) — no arbitrary point sizes
- [ ] SF Symbols match surrounding text weight and use appropriate rendering mode
- [ ] Spacing uses consistent scale values (4/8/12/16/20/24) — no arbitrary numbers
- [ ] Clear information hierarchy — primary, secondary, tertiary content visually distinct
- [ ] Toolbar uses `.toolbar {}` with correct placement and SF Symbol buttons
- [ ] Standard SwiftUI controls used — no custom reimplementations of system affordances

### macOS 26 Liquid Glass (L18)
- [ ] No custom `.toolbarBackground()` overrides — system glass treatment applies naturally
- [ ] `.tabItem()` not used — `Tab` struct used instead
- [ ] `.glassEffect()` applied only to navigation-layer elements, never to content (list rows, cards, cells)
- [ ] No glass-on-glass layering — proximate glass elements grouped in `GlassEffectContainer`
- [ ] No `.blur()`, `.opacity()`, or `.background()` modifiers on glass views
- [ ] Glass tint used for semantic meaning only, not decoration
- [ ] Toolbar buttons use `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)` as appropriate
