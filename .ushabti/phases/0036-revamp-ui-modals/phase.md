# Phase 0036: Revamp UI Modals

## Intent

Redesign the NewCardSheet, NewProjectSheet, and NewPlanSheet modals to meet macOS 26 visual design standards by applying proper layout constraints, semantic typography, consistent spacing, and Liquid Glass integration. The modals currently work functionally but do not meet Apple's design standards around visual hierarchy, spacing, and platform integration. This phase focuses purely on visual refinement without changing functionality.

## Scope

**In scope:**
- Visual refinement of all three modal sheets (NewCardSheet, NewProjectSheet, NewPlanSheet)
- Proper modal sizing with constrained dimensions and scrollable content
- Semantic typography throughout (replace arbitrary styling with system semantic styles)
- Consistent spacing using the standard scale (4, 8, 12, 16, 20, 24)
- Information hierarchy improvements (primary vs secondary content)
- Ensure Liquid Glass treatment applies correctly (toolbar/navigation only, not content)
- Review and adjust form section styling for clarity
- Ensure all sheets respect L17 (constrained modals) and L18 (native appearance)

**Out of scope:**
- Functional changes (fields, validation, save logic remain unchanged)
- Adding new fields or removing existing fields
- Changes to ViewModel methods or service layer
- Changes to other views or components beyond the three target modals
- Animated transitions or micro-interactions beyond standard SwiftUI defaults

## Constraints

- **L17 (UI State Correctness):** Modals must have constrained dimensions with scrollable content
- **L18 (Design Is How It Works):** Platform-native appearance, system controls, Liquid Glass treatment, proper visual hierarchy
- **L10 (Design Language Consistency with TakeNote):** SF Symbols, semantic font styles, consistent spacing
- **Style: Visual Design & Interaction Quality:** System colors, semantic typography, SF Symbol rendering, information hierarchy, spacing scale
- **Style: Liquid Glass:** Glass is for navigation layer (toolbar, tab bars), NOT content. Standard controls receive glass automatically.
- **Style: Modal and Sheet Sizing:** Constrained outer frame, scrollable content within
- **Style: Typography:** Use semantic styles (.headline, .body, .caption), never arbitrary point sizes
- **Style: Spacing and Layout:** Default spacing is correct, use consistent scale when overriding

## Acceptance Criteria

- All three modals (NewCardSheet, NewProjectSheet, NewPlanSheet) use constrained frame dimensions
- All text uses semantic typography styles (.headline, .body, .caption, etc.)
- Spacing follows the consistent scale (4, 8, 12, 16, 20, 24)
- Visual hierarchy is clear (primary content prominent, secondary content recedes)
- Liquid Glass treatment applies correctly to navigation elements (toolbar)
- No custom `.toolbarBackground()` overrides exist
- Dark mode appearance is correct without special-casing
- All controls use standard SwiftUI button styles
- Disabled states are visually disabled
- Documentation in `views-ui.md` is updated to reflect design improvements

## Risks / Notes

- Changes are purely visual; no functional regressions expected
- Builder should reference TakeNote patterns for consistency (L10)
- Modal sizing should ensure content scrolls, container does not grow unboundedly (L17)
- Overseer should verify visual appearance in both light and dark modes
