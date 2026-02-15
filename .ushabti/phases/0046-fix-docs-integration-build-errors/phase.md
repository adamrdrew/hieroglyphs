# Phase 0046: Fix Docs Integration Build Errors

## Intent

Fix all compilation errors and warnings introduced by the docs-integration phase (0026) so that `./Scripts/build-app.sh` exits cleanly and `swift test` passes without warnings.

## Scope

**In scope:**
- Add `Sendable` conformance to `DocsProviding` protocol
- Fix `SpotlightService` concurrency warnings (non-Sendable closure captures)
- Add missing `docsDirectory` parameter to `WorkspaceProviding.createProject` protocol definition
- Add `Hashable` conformance to `Doc` model (already has `Equatable`)
- Update two call sites (`ProjectOverview.swift` and `EditProjectSheet.swift`) to pass `docsDirectory` parameter when constructing `Project` instances

**Out of scope:**
- Feature additions or refactoring beyond what is needed to fix the build
- Changes to existing functionality or behavior
- Documentation updates (no system behavior changed)

## Constraints

- **L19:** Build MUST pass (`./Scripts/build-app.sh` exits 0) before completion
- **L11:** Tests and lint MUST pass
- **L09:** Maintain protocol-based service architecture and Sandi Metz principles
- **Style:** Fix concurrency issues properly — do not suppress warnings with `@preconcurrency` or `nonisolated(unsafe)` unless absolutely necessary

## Acceptance criteria

1. `./Scripts/build-app.sh` exits 0 with no errors or warnings
2. `swift test` passes with no failures
3. `DocsProviding` protocol conforms to `Sendable`
4. `Doc` model conforms to `Hashable`
5. `WorkspaceProviding.createProject` protocol signature includes `docsDirectory: String?` parameter
6. `SpotlightService` concurrency warnings are eliminated
7. Both `ProjectOverview.swift` and `EditProjectSheet.swift` pass `docsDirectory` when constructing `Project` instances

## Risks / notes

- SpotlightService concurrency warnings may require `@MainActor` annotation or restructuring of closure captures depending on how `NSMetadataQuery` is used. Prefer explicit actor isolation over suppression attributes.
- The two call sites constructing `Project` instances should preserve existing `docsDirectory` value from the original project when updating — do not default to `nil`.
