# Steps

## S001: Change PharaohEvent ID to stable Int

**Intent:** Replace random UUID with stable line-index-based identity so SwiftUI can diff events correctly.

**Work:**

1. Open `Sources/Hieroglyphs/Models/PharaohEvent.swift`
2. Change `let id: UUID` to `let id: Int` (line 5)
3. Update init to accept `id: Int` parameter (remove UUID default)
4. Update `parse(line:)` static method signature to `parse(line:index:)` accepting both the JSON line string and its index
5. Pass the index as the id when constructing PharaohEvent in parse method
6. Update Equatable conformance (automatic, no change needed)

**Done when:** PharaohEvent.id is Int, parse method accepts index parameter, compiles without errors.

## S002: Update PharaohService to pass line indices

**Intent:** Enumerate lines during parsing and pass indices to PharaohEvent.parse.

**Work:**

1. Open `Sources/Hieroglyphs/Services/PharaohService.swift`
2. Locate `readEvents(from:)` method (lines 133-147)
3. Change `content.split(separator: "\n").compactMap { PharaohEvent.parse(line: String($0)) }` to use `.enumerated()` and pass index:
   ```swift
   return content
       .split(separator: "\n")
       .enumerated()
       .compactMap { index, line in
           PharaohEvent.parse(line: String(line), index: index)
       }
   ```
4. Verify no other callers of `PharaohEvent.parse` exist in the codebase

**Done when:** readEvents enumerates lines and passes indices, method compiles and returns events with stable IDs.

## S003: Update PharaohProviding protocol (if needed)

**Intent:** Ensure protocol signature matches implementation.

**Work:**

1. Open `Sources/Hieroglyphs/Services/PharaohProviding.swift`
2. Verify `readEvents(from:)` signature matches implementation (no change expected — method signature is unchanged)
3. If tests or mocks reference PharaohEvent.parse directly, update them to pass index parameter

**Done when:** Protocol and implementation signatures match, no compile errors.

## S004: Add conditional assignment in PharaohView

**Intent:** Only update @State when polled values differ from current values.

**Work:**

1. Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
2. Locate `updateStatus()` method (lines 263-285)
3. Change unconditional assignments (lines 271-272, 284) to conditional:
   ```swift
   let newStatus = service.readStatus(from: sourceDirectory)
   let newServerInfo = service.readServerInfo(from: sourceDirectory)
   
   // Only assign if changed
   if newServerInfo != serverInfo {
       serverInfo = newServerInfo
   }
   
   // ... state transition logic ...
   
   previousStatus = status
   if newStatus != status {
       status = newStatus
   }
   ```
4. Verify PharaohStatus and PharaohServerInfo conform to Equatable (they already do)

**Done when:** updateStatus compares before assigning, status and serverInfo only update when values differ.

## S005: Add conditional assignment in PharaohActivityStreamView

**Intent:** Only update events array when new events exist.

**Work:**

1. Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohActivityStreamView.swift`
2. Locate `pollEvents()` method (lines 55-66)
3. Replace unconditional assignment (line 63) with conditional logic:
   ```swift
   let newEvents = service.readEvents(from: sourceDirectory)
   
   // Detect truncation (new phase started)
   if newEvents.count < events.count {
       events = newEvents
   } else if newEvents.count > events.count {
       // Append only new events
       let newItems = Array(newEvents.dropFirst(events.count))
       events.append(contentsOf: newItems)
   }
   // If counts are equal, do nothing (no change)
   ```
4. Verify PharaohEvent conforms to Equatable (it already does)

**Done when:** pollEvents appends new events only, handles truncation, skips assignment when no change.

## S006: Fix auto-scroll to trigger only on new events

**Intent:** Prevent auto-scroll from firing when events array hasn't grown.

**Work:**

1. In `PharaohActivityStreamView.swift`, locate `.onChange(of: events)` handler (lines 45-50)
2. Change to track event count instead of full array:
   ```swift
   .onChange(of: events.count) { oldCount, newCount in
       if autoScroll && newCount > oldCount {
           withAnimation {
               proxy.scrollTo("bottom", anchor: .bottom)
           }
       }
   }
   ```
3. This ensures auto-scroll only fires when count increases (new events appended)

**Done when:** Auto-scroll triggers only when events.count increases, not on every poll tick.

## S007: Update PharaohServiceTests

**Intent:** Update tests to reflect new event identity and equality-based behavior.

**Work:**

1. Open `Tests/HieroglyphsTests/PharaohServiceTests.swift`
2. Update test cases that create or parse PharaohEvent to pass index parameter
3. Add test: `testReadEventsReturnsStableIDs` — verify that parsing same file twice produces same IDs
4. Add test: `testReadEventsIndexBasedIDs` — verify IDs match line indices (first event id=0, second id=1, etc.)
5. Update any tests that compare events or check equality

**Done when:** All PharaohServiceTests pass, new tests verify stable ID behavior.

## S008: Add integration test for conditional assignment

**Intent:** Verify that polling does not update state when values are unchanged.

**Work:**

1. In `Tests/HieroglyphsTests/PharaohServiceTests.swift`, add test: `testReadStatusReturnsEqualValuesForUnchangedFile`
   - Write pharaoh.json with known status
   - Read status twice
   - Verify returned PharaohStatus instances are equal
2. Add test: `testReadEventsReturnsEqualArraysForUnchangedFile`
   - Write events.jsonl with known events
   - Read events twice
   - Verify returned arrays are equal (same IDs, same content)

**Done when:** New tests pass, verifying that re-reading unchanged files produces equal values.

## S009: Manual verification of flicker-free behavior

**Intent:** Verify that the UI does not flicker or lose state during polling.

**Work:**

1. Run the app via `swift run`
2. Start Pharaoh on a project with existing phases
3. Expand several disclosure groups in the event list (if PharaohEventDetailView uses them)
4. Observe for 10+ seconds (5+ poll cycles):
   - Event list should NOT flicker or redraw
   - Expanded disclosure groups should remain expanded
   - Scroll position should remain stable
5. Add a new event externally (append line to events.jsonl)
6. Verify new event appears within 2 seconds
7. Verify auto-scroll to bottom occurs
8. Switch to a different project and back
9. Verify events list resets correctly (no stale events from previous project)

**Done when:** Manual testing confirms flicker-free polling, stable UI state, correct auto-scroll, and proper reset on project switch.

## S010: Run full test suite

**Intent:** Verify all existing and new tests pass.

**Work:**

1. Run `swift test` from project root
2. Verify all tests pass with no failures
3. If failures occur, fix implementation or tests as needed

**Done when:** `swift test` exits with success, no test failures.
