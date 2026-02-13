# Phase 0029: Pharaoh Polling Performance

## Intent

Eliminate unnecessary view redraws in Pharaoh polling loops by implementing conditional state assignment and stable event identity. Currently, PharaohView and PharaohActivityStreamView unconditionally assign polled data to @State every 2 seconds, triggering full view updates even when nothing changed. This causes event list flickering, disclosure group collapse, and general UI sluggishness.

This phase implements the "Polling and Live Data" pattern from style.md: equality checks before assignment, append-not-replace for lists, and stable Identifiable IDs.

## Scope

**In scope:**

- Change PharaohEvent.id from UUID to stable Int (line index in JSONL file)
- Update PharaohService.readEvents to pass line indices during parsing
- Add conditional assignment in PharaohView (compare before updating status and serverInfo)
- Add conditional assignment in PharaohActivityStreamView (compare before updating events array)
- Implement append-only event loading (detect new events, append rather than replace)
- Fix auto-scroll to trigger only when event count increases
- Update PharaohProviding protocol if method signatures change
- Update all tests to reflect new event identity and equality-based behavior
- Verify existing functionality preserved (event display, auto-scroll, status monitoring, auto-complete)

**Out of scope:**

- Changing poll interval (2 seconds is acceptable once redraws are conditional)
- Switching from polling to FSEvents/file watching for events.jsonl
- File modification date caching (optimization not required for this fix)
- Any reactive frameworks (Combine, AsyncSequence) — use plain async/await and SwiftUI state

## Constraints

- **L09:** Sandi Metz principles — small, focused methods with single responsibility
- **L11:** Test coverage — all public API methods must have tests
- **L17:** UI State Correctness — polling-driven views must not trigger redraws when content has not changed
- **Style: Polling and Live Data** — equality check before assignment, append-not-replace, preserve user interaction state
- **Style: SwiftUI UX Patterns** — maintain stable scroll position, preserve expanded disclosure groups across data refreshes

## Acceptance Criteria

1. Event list does NOT visually refresh when no new events appended (no flicker, no scroll jump, no disclosure group collapse)
2. Expanded disclosure groups remain expanded across poll ticks
3. New events appear at bottom of list within 2 seconds of being written
4. Auto-scroll works when new events are appended (scrolls to bottom)
5. Auto-scroll does NOT trigger when no new events exist
6. Pharaoh status panel does not flicker or redraw when status unchanged
7. General app responsiveness (typing, switching views, scrolling) not degraded while Pharaoh polls
8. All existing tests pass
9. New tests verify equality-based assignment skipping and stable event identity
10. Switching from long event stream to new phase (events.jsonl truncated) resets list correctly

## Risks / Notes

- **Breaking change:** PharaohEvent.id changes from UUID to Int. This is acceptable because PharaohEvent is internal to Hieroglyphs (not a public API).
- **Edge case:** If events.jsonl is truncated or replaced (new phase starts), detect via count comparison and reset the array. Implementation: if `allEvents.count < events.count`, replace entire array rather than append.
- **Testing strategy:** Manual verification required for flicker-free behavior. Automated tests verify functional correctness (equality skipping, stable IDs, append logic).
