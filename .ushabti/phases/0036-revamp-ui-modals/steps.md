# Steps

## S001: Redesign NewPlanSheet

**Intent:** Simplest modal (single field), good starting point for establishing design patterns.

**Work:**
- Apply constrained frame with appropriate modal dimensions
- Review section layout and spacing
- Apply semantic typography throughout
- Ensure toolbar uses glass treatment (should be automatic)
- Test visual hierarchy
- Verify dark mode appearance

**Done when:** NewPlanSheet displays with proper sizing, semantic fonts, consistent spacing, and clean visual hierarchy in both light and dark modes.

## S002: Redesign NewProjectSheet

**Intent:** Mid-complexity modal with multiple fields and directory picker; apply patterns from NewPlanSheet.

**Work:**
- Apply constrained frame with appropriate modal dimensions
- Review multi-line description field layout
- Improve source directory picker visual layout (button hierarchy, spacing)
- Apply semantic typography throughout
- Consistent spacing in sections
- Ensure clear/select buttons have proper styling
- Verify dark mode appearance

**Done when:** NewProjectSheet displays with proper sizing, semantic fonts, improved directory picker layout, and consistent spacing in both light and dark modes.

## S003: Redesign NewCardSheet

**Intent:** Most complex modal with pickers, tags, and body editor; apply full design system.

**Work:**
- Apply constrained frame with proper modal dimensions
- Ensure Body TextEditor section scrolls within constrained height (verify existing implementation)
- Apply semantic typography to all fields
- Review picker layout and spacing
- Ensure tags field and body section have clear visual separation
- Test overall information hierarchy
- Verify dark mode appearance

**Done when:** NewCardSheet displays with proper sizing, constrained body editor, semantic fonts, and clear visual hierarchy in both light and dark modes.

## S004: Verify Liquid Glass and Platform Integration

**Intent:** Ensure all three modals properly integrate with macOS 26 Liquid Glass and platform conventions.

**Work:**
- Verify toolbars receive automatic glass treatment in all three modals
- Confirm no custom `.toolbarBackground()` overrides exist
- Check that all buttons use standard button styles (.borderedProminent, .borderless, etc.)
- Verify dark mode appearance across all three modals
- Test that controls communicate their state (disabled buttons visually disabled)
- Verify spacing consistency across all three modals

**Done when:** All three modals display correct Liquid Glass treatment, respect dark mode, use standard controls throughout, and have consistent visual patterns.

## S005: Reconcile Documentation

**Intent:** Update `.ushabti/docs/views-ui.md` to reflect modal design improvements.

**Work:**
- Update NewCardSheet documentation section with design notes (modal sizing, typography, visual hierarchy)
- Update NewProjectSheet documentation section with design notes
- Update NewPlanSheet documentation section with design notes
- Document modal sizing patterns used across all three sheets
- Document visual hierarchy patterns applied
- Note Liquid Glass integration approach

**Done when:** `views-ui.md` accurately describes the redesigned modals, their visual design patterns, and sizing constraints.
