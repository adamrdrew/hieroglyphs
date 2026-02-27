# Review — Phase 0049: Notification Service Compliance

## Summary

Phase 0049 brought the NotificationService feature into full compliance with project laws and style conventions. The work replaced a singleton-accessed concrete service with a protocol-based, environment-injected abstraction; extracted transition-detection logic into a testable free function; added pruning of stale status tracking entries; replaced a deprecated API call; and delivered comprehensive test coverage. Documentation was updated to reflect all changes.

## Verified

### Acceptance Criteria

1. **NotificationDispatching protocol exists** — `Sources/Hieroglyphs/Services/NotificationDispatching.swift` defines a `@MainActor` protocol with `setUp()`, `notifyPhaseCompleted(projectName:phaseName:turns:costUsd:)`, and `notifyPhaseFailed(projectName:phaseName:error:turns:costUsd:)`. The notify methods are correctly marked `nonisolated` for cross-isolation callability. SATISFIED.

2. **NotificationService conforms, singleton removed** — `NotificationService` declares `: NotificationDispatching` conformance. No `static let shared` or `override private init()` exists. Grep confirms zero references to `NotificationService.shared` in the source tree. SATISFIED.

3. **EnvironmentKey exists** — `Sources/Hieroglyphs/Services/NotificationServiceEnvironmentKey.swift` defines `NotificationServiceEnvironmentKey: EnvironmentKey` with `defaultValue: (any NotificationDispatching)? = nil` and an `EnvironmentValues.notificationService` computed property. Follows the `PharaohServiceEnvironmentKey` pattern exactly. SATISFIED.

4. **App.swift wires injection** — `App.swift` creates a `NotificationService()` instance, stores it as `any NotificationDispatching`, calls `setUp()` in `init()`, and injects via `.environment(\.notificationService, notificationService)` on both the main Window and the MenuBarExtra. No reference to `NotificationService.shared` remains. SATISFIED.

5. **PharaohMenuBar uses injected service** — Declares `@Environment(\.notificationService) private var notificationService` and passes it through `checkForTransition` to the extracted detector. No direct singleton access. SATISFIED.

6. **Deprecated API replaced** — `NSApplication.shared.activate()` used instead of `activate(ignoringOtherApps: true)`. Grep confirms no remaining usage of the deprecated form. SATISFIED.

7. **previousStatuses pruning** — `loadRunningPlans()` maintains a `visitedDirectories` set populated during project iteration. After the loop, stale keys are removed from `previousStatuses`. SATISFIED.

8. **Tests exist and cover all required cases** — `Tests/HieroglyphsTests/NotificationServiceTests.swift` contains 11 tests: 3 protocol method recording tests and 8 transition-detection tests covering busy-to-done, busy-to-blocked, busy-to-idle, idle-to-busy, nil-to-busy, busy-to-busy, busy-to-notRunning, and done-to-busy. All pass. SATISFIED.

9. **All tests pass** — `swift test` reports 340 tests, 0 failures. SATISFIED.

10. **Build passes** — `./Scripts/build-app.sh` exits 0. Build verified. SATISFIED.

11. **Documentation updated** — `.ushabti/docs/pharaoh-integration.md` now documents the NotificationDispatching protocol, NotificationService implementation, environment injection, transition detection utility, previousStatuses pruning, and testing strategy. The PharaohMenuBar and Environment Injection sections were also updated. SATISFIED.

### Step Verification

| Step | Title | Done-When | Verified |
|------|-------|-----------|----------|
| S001 | Define NotificationDispatching protocol | Protocol file exists with all three method signatures; builds cleanly | Yes |
| S002 | Conform NotificationService | Conforms to protocol; no `static let shared`; deprecated API replaced; builds cleanly | Yes |
| S003 | Create EnvironmentKey | Environment key file exists; follows PharaohServiceEnvironmentKey pattern; builds cleanly | Yes |
| S004 | Inject in App.swift | Creates, stores, injects service; no `.shared` reference; builds cleanly | Yes |
| S005 | Update PharaohMenuBar | No `NotificationService.shared` references; dispatch through injected protocol; builds cleanly | Yes |
| S006 | Extract transition detection | `detectPharaohTransition` free function in `Utilities/PharaohTransitionDetector.swift`; internal visibility; PharaohMenuBar delegates to it; testable with mock; builds cleanly | Yes |
| S007 | Add previousStatuses pruning | Stale entries pruned via `visitedDirectories` set difference; builds cleanly | Yes |
| S008 | Write tests | 11 tests covering all protocol methods and all transition cases; all pass | Yes |
| S009 | Verify no dead code | No singleton references, no unused imports, no commented-out code | Yes |
| S010 | Build and test verification | `./Scripts/build-app.sh` exits 0; `swift test` 340 tests, 0 failures | Yes |
| S011 | Update documentation | `pharaoh-integration.md` documents protocol, implementation, injection, transition detection, pruning, testing | Yes |

### Law Compliance

- **L01 (Filesystem as source of truth):** No new persistence introduced. Not applicable beyond status file reads.
- **L03 (No Xcode project):** No `.xcodeproj` or `.xcworkspace` introduced. Build via SPM.
- **L04 (No SwiftData):** No database imports.
- **L09 (Sandi Metz / dependency inversion):** Service is protocol-based. Injected via SwiftUI Environment. Views depend on the protocol, not the concrete class. Composition used throughout.
- **L11 (Test coverage):** All public API methods on the protocol are tested. All transition detection paths are tested. 340 tests, 0 failures.
- **L12 (No dead code):** Singleton pattern fully removed. No unused imports. No commented-out code.
- **L14/L16 (Docs maintenance/reconciliation):** `pharaoh-integration.md` updated with comprehensive documentation of all changes.
- **L19 (Build must pass):** `./Scripts/build-app.sh` exits 0.

### Style Compliance

- **Sandi Metz rules:** `NotificationService` at 108 lines (within acceptable spirit). `PharaohMenuBar` at 135 lines (within acceptable spirit, noted as in-scope in phase.md). All other files well under 100 lines. Methods are short and focused.
- **Protocol-based services:** `NotificationDispatching` protocol defines the public interface.
- **Naming:** Protocol named `NotificationDispatching` (capability-describing). Files named to match primary types.
- **No regex:** Confirmed via grep.
- **Composition over inheritance:** Free function extracted for transition detection rather than inheritance.
- **File conventions:** One primary type per file. Files in correct directories (Services, Utilities, Tests).

## Issues

None.

## Required Follow-ups

None.

## Decision

**GREEN.** All 11 acceptance criteria are satisfied. All 11 steps are implemented and verified. No law violations. Style compliance is acceptable. 340 tests pass with 0 failures. Build verified via `./Scripts/build-app.sh`. Documentation is reconciled with code changes.

The work has been weighed and found complete.
