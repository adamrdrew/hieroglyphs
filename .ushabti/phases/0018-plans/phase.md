# Phase 0018: Plans

## Intent

Add Plans as a new directory type in the Hieroglyphs workspace that groups cards via symlinks and can generate a PHASE_PROMPT.md file for Ushabti Scribe.

Plans serve as a bounded unit of work within a project. A Plan links to cards that collectively achieve a cohesive goal and can produce a phase prompt when the user is ready to transition from planning to implementation.

This phase fills in the Plans section placeholder created in Phase 0015.

## Scope

### In Scope

- New `Plan` model with id, title, number, slug, status, timestamps
- New `PlanStatus` enum (planning, ready, done)
- New `PlanService` protocol and implementation for filesystem I/O:
  - Load plans from `{projectPath}/plans/` directories
  - Create plans with number and title
  - Add cards to plans (create relative symlinks)
  - Remove cards from plans (delete symlinks)
  - Update plan status (when done, mark all linked cards done)
  - Write PHASE_PROMPT.md content
  - Handle dangling symlinks gracefully
- New `PlanList` view (middle column):
  - Shows plans with number, title, status, linked card count
  - "New Plan" button in toolbar
  - Empty state
- New `PlanDetail` view (right column):
  - Plan number, title, status picker
  - List of linked cards with title/status/priority
  - "Add Card" action (picker of available cards)
  - Remove card action (context menu)
  - PHASE_PROMPT.md content area (editable text editor)
  - "Generate Phase Prompt" button (placeholder for future)
- Wire into MainWindow: `.plans(project)` shows PlanList
- Update FileWatcher to detect changes in `plans/` directories
- Complete tests for PlanService
- Documentation updates for Plans system

### Out of Scope

- Phase prompt generation logic (placeholder button only)
- Plan templates
- Plan archiving
- Plan reordering
- Card dependency tracking within plans
- Multi-project plans
- Plan export/import

## Constraints

### Relevant Laws

- **L01 (Filesystem as Source of Truth):** Plans stored as `plan.yaml` with symlinks to cards
- **L02 (Preserve Unknown Fields):** plan.yaml may contain unknown fields
- **L05 (External Changes First-Class):** FileWatcher must detect plan changes
- **L06 (Platform Leverage):** Use FileManager for symlink operations
- **L09 (Protocol-Based Services):** PlanService defined as protocol with concrete implementation
- **L11 (Test Coverage):** All public PlanService methods tested
- **L14 (Builder Docs Maintenance):** Update docs to describe Plans system

### Relevant Style

- Services are protocol-based and stateless
- Models are plain structs with no business logic
- Views are small and composable
- Symlinks must be relative, not absolute
- Slug format: `{NNNN}-{kebab-case-title}` where NNNN is zero-padded number
- Yams for YAML parsing/serialization
- Error handling follows "do your best" philosophy

### Technical Constraints

- Symlinks point to card directories: `../../cards/{card-slug}/`
- plan.yaml uses same YAML format as project.md and card.md frontmatter
- PlanService injected via environment like WorkspaceService
- Dangling symlinks detected and shown as "Missing: card-slug" in UI
- When a plan status becomes "done", all linked cards get status "done"
- PHASE_PROMPT.md is plain markdown, initially empty on plan creation

## Acceptance Criteria

1. User can create a new plan with a number and title via PlanList toolbar button
2. User can view all plans in the middle column when Plans section is selected
3. User can select a plan and see its details (number, title, status, linked cards, PHASE_PROMPT.md)
4. User can add a card to a plan, creating a relative symlink on disk at `{projectPath}/plans/{plan-slug}/{card-slug} -> ../../cards/{card-slug}/`
5. User can remove a card from a plan, deleting the symlink
6. Plan list shows card count for each plan (count of symlinks in plan directory)
7. User can change plan status via picker in PlanDetail
8. When plan status becomes "done", all linked cards have status updated to "done" on disk
9. Dangling symlinks (card deleted) are shown as "Missing: card-slug" rather than crashing
10. User can edit PHASE_PROMPT.md content in PlanDetail
11. PHASE_PROMPT.md content persists to `{projectPath}/plans/{plan-slug}/PHASE_PROMPT.md`
12. FileWatcher detects external changes to plan.yaml and PHASE_PROMPT.md
13. Tests cover all PlanService public methods
14. Docs updated with Plans system architecture

## Risks / Notes

### Risks

- Symlink resolution could fail if cards are moved/renamed (mitigated: show as "Missing" in UI)
- Plan numbers may collide if users create plans manually (mitigated: document convention, future enhancement for collision detection)
- Marking plan done could overwrite user intent for cards with non-done status (mitigated: document behavior, user must confirm via status picker)

### Notes

- "Generate Phase Prompt" button is a placeholder. Actual generation logic will be implemented externally or in a future phase.
- Plans are scoped to a single project. Multi-project plans are out of scope.
- Plan.linkedCardSlugs is derived from symlink enumeration, not stored in plan.yaml
- Card deletion does not automatically remove symlinks (dangling symlinks are tolerated and shown as missing)
