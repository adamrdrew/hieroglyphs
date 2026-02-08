# Phase 0012: Fix Typing Lag in Card Editor

## Intent

Eliminate typing lag in card body editor caused by synchronous disk writes on every keystroke. Users currently experience noticeable delays when typing because each character triggers a full write-to-disk and reload-from-disk cycle. This Phase introduces debouncing to batch writes while maintaining filesystem-as-truth semantics.

## Scope

**In scope:**
- Investigate and confirm root cause of typing lag
- Add debounced write mechanism for card body updates
- Add debounced write mechanism for card title updates
- Ensure debounced writes flush on card deselection or app termination
- Preserve L01 (Filesystem as Source of Truth) by ensuring all edits reach disk
- Add tests for debouncing behavior

**Out of scope:**
- Optimizing project-level operations (not a reported performance issue)
- Optimizing card list reload performance (separate concern)
- Conflict resolution for concurrent edits (deferred to future phase)
- Debouncing picker changes (type, status, priority) as these are discrete actions, not continuous typing
- Tag add/remove debouncing (discrete actions)

## Constraints

**Laws:**
- L01 (Filesystem as Source of Truth): Debounced writes must eventually reach disk. No edits can be lost.
- L05 (External Changes Are First-Class): File watcher must continue to detect external changes correctly
- L09 (Sandi Metz Principles): Small methods, single responsibility, protocol-based design
- L11 (Test Coverage): All new public methods must have tests
- L12 (No Dead Code): Remove any obsolete immediate-write logic if replaced

**Style:**
- Small classes and methods
- Composition over inheritance
- Clear naming that expresses intent
- No regex (not applicable here)

## Acceptance Criteria

1. **Root cause confirmed**: Investigation step documents that `updateCard()` writes to disk on every keystroke
2. **Typing is responsive**: User can type continuously in card body editor without noticeable lag
3. **Title editing is responsive**: User can type continuously in card title field without noticeable lag
4. **Edits reach disk**: All typed content is written to disk within a reasonable delay (e.g., 1-2 seconds after last keystroke)
5. **Edits flush on deselection**: When user selects a different card, pending writes complete before new card loads
6. **Edits flush on app quit**: When user quits app, pending writes complete before shutdown
7. **Tests pass**: All existing tests pass, new debouncing tests added and passing
8. **Docs reconciled**: ViewModel and Views documentation updated to reflect debouncing behavior

## Risks / Notes

**Debounce delay tradeoff:** Longer delays reduce disk I/O but increase window for data loss on crash. 1-2 second delay is standard practice and acceptable risk given macOS stability.

**External file watcher interaction:** Debounced writes will trigger file watcher events. This is correct behavior per L05. File watcher should not reload the currently-edited card to avoid disrupting the user's work.

**Discrete vs continuous edits:** Picker changes (type, status, priority) and tag operations are discrete user actions that complete immediately, so immediate writes are appropriate. Only continuous typing (title, body) benefits from debouncing.

**Deferred work:** Conflict detection when external tool edits same card during debounce window is out of scope. This is a known limitation acceptable for v1.
