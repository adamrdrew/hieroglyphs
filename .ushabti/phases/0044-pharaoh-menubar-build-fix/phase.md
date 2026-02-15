# Phase 0044: PharaohMenuBar Build Fix

## Intent

Fix two compilation errors in `PharaohMenuBar.swift` that prevent the app from building. The errors cascade to `App.swift` and block all compilation.

## Scope

**In scope:**
- Wrap conditional view structure in `Group` to enable view modifier attachment
- Remove non-Optional `planService` from guard-let statement
- Verify `swift build` succeeds after fixes

**Out of scope:**
- Behavioral changes to PharaohMenuBar functionality
- Refactoring polling logic or state management
- Changes to PharaohMenuBarEntry or other menu bar components

## Constraints

- **L19**: Build must pass via `./Scripts/build-app.sh`
- **Style**: Sandi Metz principles (minimal change, preserve existing structure)
- **Style**: No behavioral changes — preserve polling logic, empty state handling, and plan loading as-is

## Acceptance criteria

- `swift build` completes successfully with exit code 0
- View modifiers (`.onAppear`, `.onReceive`) correctly attach to a concrete view type
- No guard-let on non-Optional `planService`
- PharaohMenuBar continues to display running plans and poll every 3 seconds as before
- No other files modified beyond `PharaohMenuBar.swift`

## Risks / notes

This is a surgical fix for two syntax errors. The underlying polling pattern and state management remain unchanged. Future phases may refactor this view's polling behavior per UX patterns in style guide, but that is explicitly out of scope here.
