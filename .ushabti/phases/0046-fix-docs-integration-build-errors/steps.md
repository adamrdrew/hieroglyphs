# Steps

## S001: Add Sendable conformance to DocsProviding protocol

**Intent:** Eliminate concurrency safety error for `DocsServiceEnvironmentKey.defaultValue`.

**Work:**
- Open `Sources/Hieroglyphs/Services/DocsProviding.swift`
- Change protocol declaration from `protocol DocsProviding` to `protocol DocsProviding: Sendable`
- Verify `DocsService` implementation is concurrency-safe (it is: uses FileManager and has no mutable state)

**Done when:** `DocsProviding` protocol inherits from `Sendable`.

## S002: Add Hashable conformance to Doc model

**Intent:** Satisfy SwiftUI `List` and `.tag()` requirements in `DocsList.swift`.

**Work:**
- Open `Sources/Hieroglyphs/Models/Doc.swift`
- Change struct declaration from `struct Doc: Identifiable, Equatable` to `struct Doc: Identifiable, Equatable, Hashable`
- No additional implementation needed (synthesized automatically)

**Done when:** `Doc` conforms to `Hashable`.

## S003: Add docsDirectory parameter to WorkspaceProviding.createProject protocol

**Intent:** Fix protocol conformance error in `WorkspaceService`.

**Work:**
- Open `Sources/Hieroglyphs/Services/WorkspaceProviding.swift`
- Locate `createProject` function signature (around line 78)
- Add `docsDirectory: String?,` parameter after `sourceDirectory` and before `buildCommand`
- Update documentation comment to describe the new parameter

**Done when:** Protocol signature matches implementation in `WorkspaceService.swift`.

## S004: Fix SpotlightService concurrency warnings

**Intent:** Eliminate non-Sendable closure capture warnings.

**Work:**
- Open `Sources/Hieroglyphs/Services/SpotlightService.swift`
- Locate the problematic closure (around line 80)
- Analyze whether `SpotlightService` should be `@MainActor` isolated or whether weak/unowned capture is appropriate
- Apply the correct fix: either annotate class with `@MainActor`, use `[weak self]` capture, or mark the closure as `@MainActor`
- Verify `NSMetadataQuery` is also `Sendable` or mark as `@preconcurrency import` if necessary

**Done when:** No concurrency warnings appear in `SpotlightService.swift` when building.

## S005: Update ProjectOverview.swift to pass docsDirectory

**Intent:** Fix missing argument compilation error.

**Work:**
- Open `Sources/Hieroglyphs/Views/ProjectOverview/ProjectOverview.swift`
- Locate `Project(...)` init call around line 226
- Add `docsDirectory: project.docsDirectory,` between `sourceDirectory` and `buildCommand` parameters
- Preserve existing value from the original project

**Done when:** Build error eliminated for this call site.

## S006: Update EditProjectSheet.swift to pass docsDirectory

**Intent:** Fix missing argument compilation error.

**Work:**
- Open `Sources/Hieroglyphs/Views/Sidebar/EditProjectSheet.swift`
- Locate `Project(...)` init call around line 104
- Add `docsDirectory: project.docsDirectory,` between `sourceDirectory` and `buildCommand` parameters
- Preserve existing value from the original project

**Done when:** Build error eliminated for this call site.

## S007: Run build and verify all errors resolved

**Intent:** Confirm all compilation errors and warnings are fixed.

**Work:**
- Run `./Scripts/build-app.sh` from repository root
- Verify exit code is 0
- Verify no errors or warnings appear in output

**Done when:** Build exits 0 with no errors or warnings.

## S008: Run tests and verify they pass

**Intent:** Confirm changes do not break existing functionality.

**Work:**
- Run `swift test` from repository root
- Verify all tests pass
- Check for any new test failures or deprecation warnings

**Done when:** All tests pass.
