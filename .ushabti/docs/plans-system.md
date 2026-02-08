# Plans System

## Overview

Plans group cards into bounded units of work via symlinks and can generate Ushabti phase prompts. A Plan links to cards that collectively achieve a cohesive goal and produces a phase prompt file when the user is ready to transition from planning to implementation.

**Models:** `Plan`, `PlanStatus`
**Service:** `PlanProviding` protocol, `PlanService` implementation
**Views:** `PlanList`, `PlanListEntry`, `PlanDetail`, `NewPlanSheet`, `AddCardToPlanSheet`
**Location:** `Sources/Hieroglyphs/Models/`, `Sources/Hieroglyphs/Services/`, `Sources/Hieroglyphs/Views/PlanList/`, `Sources/Hieroglyphs/Views/PlanDetail/`

The Plans system supports L01 (Filesystem as Source of Truth), L02 (Preserve Unknown Fields), L05 (External Changes First-Class), L06 (Platform Leverage with symlinks), and L09 (Protocol-Based Design).

## Filesystem Structure

Plans are stored in `{projectPath}/plans/` directories. Each plan has:

- **Directory:** `{projectPath}/plans/{NNNN}-{kebab-case-title}/`
- **Metadata file:** `plan.yaml`
- **Phase prompt file:** `PHASE_PROMPT.md`
- **Card symlinks:** `{card-slug}` → `../../cards/{card-slug}/`

**Example structure:**

```
{workspacePath}/
  my-project/
    project.md
    cards/
      card-1/
        card.md
      card-2/
        card.md
    plans/
      0001-initial-setup/
        plan.yaml
        PHASE_PROMPT.md
        card-1          # symlink → ../../cards/card-1/
        card-2          # symlink → ../../cards/card-2/
```

## Plan Model

**Location:** `Sources/Hieroglyphs/Models/Plan.swift`

**Purpose:** Represents a plan with metadata and linked cards.

**Fields:**

- `id: UUID` — Unique identifier for the plan
- `title: String` — Human-readable plan title
- `number: Int` — Plan number (used in slug)
- `slug: String` — Filesystem-safe slug: `{NNNN}-{kebab-case-title}`
- `status: PlanStatus` — Current plan status (planning, ready, done)
- `created: Date` — ISO8601 timestamp of plan creation
- `updated: Date` — ISO8601 timestamp of last update
- `linkedCardSlugs: [String]` — Array of card slugs (derived from symlinks, not persisted)
- `phasePrompt: String` — Content of PHASE_PROMPT.md file

**Conformances:** `Identifiable`, `Codable`, `Equatable`, `Hashable`

**Notes:**

- `slug` format is `{NNNN}-{kebab-case-title}` where NNNN is zero-padded number (e.g., `0001-initial-setup`)
- `linkedCardSlugs` is derived by enumerating symlinks in the plan directory, not stored in `plan.yaml`
- `phasePrompt` is read from `PHASE_PROMPT.md` file
- Plans are displayed in PlanList and PlanDetail views

## PlanStatus Enum

**Location:** `Sources/Hieroglyphs/Models/PlanStatus.swift`

**Purpose:** Enum representing the current status of a plan.

**Cases:**

- `planning` — Plan is being designed and cards are being added
- `ready` — Plan is complete and ready for execution
- `done` — Plan has been executed and all work is complete

**Conformances:** `String`, `Codable`, `CaseIterable`

**Notes:**

- Raw values are lowercase strings matching enum case names
- Stored in plan.yaml `status` field as raw string (e.g., `status: planning`)
- Status progression: planning → ready → done
- When status becomes `done`, all linked cards have their status updated to `done`

## plan.yaml Format

**Location:** `{projectPath}/plans/{plan-slug}/plan.yaml`

**Purpose:** Store plan metadata in YAML format.

**Format:** YAML file with plan fields (no body content).

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID string | Yes | Unique identifier |
| `title` | String | Yes | Human-readable title |
| `number` | Int | Yes | Plan number |
| `slug` | String | Yes | Filesystem-safe slug (must match directory name) |
| `status` | String enum | No | Plan status: `planning`, `ready`, `done` (defaults to `planning`) |
| `created` | ISO8601 date string | No | Creation timestamp (defaults to current date) |
| `updated` | ISO8601 date string | No | Last update timestamp (defaults to current date) |

**Example:**

```yaml
id: 123e4567-e89b-12d3-a456-426614174000
title: Initial Setup
number: 1
slug: 0001-initial-setup
status: planning
created: 2026-01-15T10:30:00Z
updated: 2026-01-20T14:22:00Z
```

**Notes:**

- `slug` field must match directory name exactly
- Unknown fields are preserved per L02 (e.g., custom `owner` or `priority` fields)
- `linkedCardSlugs` is NOT stored in plan.yaml (derived from symlinks)

## PHASE_PROMPT.md

**Location:** `{projectPath}/plans/{plan-slug}/PHASE_PROMPT.md`

**Purpose:** Store user-editable phase prompt content for Ushabti integration.

**Format:** Plain markdown file.

**Content:** User-defined markdown content describing the phase goals, scope, and constraints for Ushabti Scribe to plan implementation.

**Example:**

```markdown
# Phase Prompt: Initial Setup

## Goal

Set up the project repository and build infrastructure.

## Scope

- Initialize Git repository
- Configure Swift Package Manager
- Add CI/CD pipeline

## Out of Scope

- Documentation
- Testing infrastructure

## Constraints

- Must use SPM (no Xcode project)
- macOS 26 only
```

**Notes:**

- Initially empty when plan is created
- Editable in PlanDetail view via TextEditor
- Changes are written to disk immediately (not debounced)
- Used by Ushabti Scribe to generate phase plans (future enhancement)

## Symlinks

Plans use **relative symlinks** to link to cards. This enables workspace portability (moving the workspace to a different path preserves symlinks).

**Symlink format:**

```
{projectPath}/plans/{plan-slug}/{card-slug} → ../../cards/{card-slug}/
```

**Example:**

```
/Users/alice/Hieroglyphs/my-project/plans/0001-initial-setup/card-1
  → ../../cards/card-1/
```

**Notes:**

- Symlinks point to card directories, not card.md files
- Symlinks are relative (two levels up, then into cards directory)
- Dangling symlinks (card deleted) are tolerated and shown as "Missing: card-slug" in UI
- FileManager.createSymbolicLink() used to create symlinks
- Card deletion removes symlinks from all plans via `removeCardSymlinksFromPlans()` (best-effort, orchestrated by ViewModel)

## PlanProviding Protocol

**Location:** `Sources/Hieroglyphs/Services/PlanProviding.swift`

**Purpose:** Define the contract for plan I/O operations.

**Methods:**

### loadPlans(projectPath:)

**Signature:** `func loadPlans(projectPath: String) throws -> [Plan]`

**Purpose:** Load all plans for a given project path.

**Parameters:**

- `projectPath` — Absolute path to project directory

**Returns:** Array of `Plan` objects (may be empty if no plans exist).

**Throws:** Rarely throws (returns empty array if `plans/` directory missing).

**Behavior:**

1. Construct path to `{projectPath}/plans/`
2. If `plans/` directory does not exist, return empty array
3. Scan `plans/` directory for subdirectories containing `plan.yaml`
4. For each plan directory:
   - Read `plan.yaml`
   - Parse YAML via `Yams.load()`
   - Enumerate symlinks to derive `linkedCardSlugs`
   - Read `PHASE_PROMPT.md` content (empty string if missing)
   - Construct `Plan` model
5. Skip plans with missing required fields (log warning)
6. Skip plans with parsing errors (log warning)
7. Return array of successfully parsed plans

### createPlan(title:number:projectPath:)

**Signature:** `func createPlan(title: String, number: Int, projectPath: String) throws -> Plan`

**Purpose:** Create a new plan with the given title and number.

**Parameters:**

- `title` — Plan title
- `number` — Plan number (used in slug)
- `projectPath` — Absolute path to project directory

**Returns:** The created `Plan` model.

**Throws:**

- `PlanError.directoryCreationFailed` if directory creation fails
- `PlanError.fileWriteFailed` if file write fails

**Behavior:**

1. Generate slug: `{NNNN}-{kebab-case-title}` where NNNN is zero-padded number
2. Create `plans/` directory if it doesn't exist
3. Create plan directory at `{projectPath}/plans/{slug}/`
4. Generate new UUID for `id`
5. Set `created` and `updated` to current date
6. Set `status` to `planning`
7. Write `plan.yaml` via `Yams.dump()`
8. Write empty `PHASE_PROMPT.md`
9. Return `Plan` model

### updatePlan(_:projectPath:)

**Signature:** `func updatePlan(_ plan: Plan, projectPath: String) throws`

**Purpose:** Update an existing plan's metadata.

**Parameters:**

- `plan` — Updated plan model
- `projectPath` — Absolute path to project directory

**Throws:**

- `PlanError.planNotFound` if plan.yaml does not exist
- `PlanError.fileWriteFailed` if file write fails

**Behavior:**

1. Construct path to `{projectPath}/plans/{plan.slug}/plan.yaml`
2. Check file exists (throw `planNotFound` if missing)
3. Read existing file
4. Parse YAML via `Yams.load()`
5. Merge updated fields into existing dictionary (preserving unknown fields)
6. Update `updated` timestamp to current date
7. Write back via `Yams.dump()`

**Notes:** Preserves unknown frontmatter fields per L02.

### addCardToPlan(cardSlug:planSlug:projectPath:)

**Signature:** `func addCardToPlan(cardSlug: String, planSlug: String, projectPath: String) throws`

**Purpose:** Add a card to a plan by creating a symlink.

**Parameters:**

- `cardSlug` — Slug of card to add
- `planSlug` — Slug of plan to add card to
- `projectPath` — Absolute path to project directory

**Throws:**

- `PlanError.cardNotFound` if card directory does not exist
- `PlanError.symlinkCreationFailed` if symlink creation fails

**Behavior:**

1. Verify card directory exists at `{projectPath}/cards/{cardSlug}/`
2. Create relative symlink: `{projectPath}/plans/{planSlug}/{cardSlug} → ../../cards/{cardSlug}/`
3. Use `FileManager.createSymbolicLink()`

### removeCardFromPlan(cardSlug:planSlug:projectPath:)

**Signature:** `func removeCardFromPlan(cardSlug: String, planSlug: String, projectPath: String) throws`

**Purpose:** Remove a card from a plan by deleting the symlink.

**Parameters:**

- `cardSlug` — Slug of card to remove
- `planSlug` — Slug of plan to remove card from
- `projectPath` — Absolute path to project directory

**Throws:**

- `PlanError.planNotFound` if symlink does not exist
- `PlanError.fileWriteFailed` if deletion fails

**Behavior:**

1. Construct path to `{projectPath}/plans/{planSlug}/{cardSlug}`
2. Delete symlink via `FileManager.removeItem()`

### updatePlanStatus(plan:status:projectPath:)

**Signature:** `func updatePlanStatus(plan: Plan, status: PlanStatus, projectPath: String) throws`

**Purpose:** Update a plan's status and cascade to linked cards if status is "done".

**Parameters:**

- `plan` — Plan to update
- `status` — New status
- `projectPath` — Absolute path to project directory

**Throws:**

- `PlanError.planNotFound` if plan does not exist
- `PlanError.fileWriteFailed` if write fails

**Behavior:**

1. Update plan status in `plan.yaml` via `updatePlan()`
2. If status is `done`:
   - Enumerate symlinks to get linked card slugs
   - For each linked card:
     - Read card.md
     - Parse frontmatter
     - Set `status` to `done`
     - Update `updated` timestamp
     - Write card back to disk
   - Skip dangling symlinks with warning log

### writePhasePrompt(planSlug:content:projectPath:)

**Signature:** `func writePhasePrompt(planSlug: String, content: String, projectPath: String) throws`

**Purpose:** Write phase prompt content to PHASE_PROMPT.md.

**Parameters:**

- `planSlug` — Slug of plan
- `content` — Markdown content to write
- `projectPath` — Absolute path to project directory

**Throws:**

- `PlanError.fileWriteFailed` if file write fails

**Behavior:**

1. Construct path to `{projectPath}/plans/{planSlug}/PHASE_PROMPT.md`
2. Write content atomically

### removeCardSymlinksFromPlans(cardSlug:projectPath:)

**Signature:** `func removeCardSymlinksFromPlans(cardSlug: String, projectPath: String) throws`

**Purpose:** Remove all symlinks to a card from all plans when the card is deleted. Best-effort cleanup that prevents dangling symlinks.

**Parameters:**

- `cardSlug` — Slug of card being deleted
- `projectPath` — Absolute path to project directory

**Throws:**

- Rarely throws (returns silently if plans directory missing)

**Behavior:**

1. Check if `{projectPath}/plans/` exists; return silently if not
2. Enumerate all plan directories via `discoverPlanDirectories()`
3. For each plan directory:
   - Check if symlink named `cardSlug` exists
   - Verify it is a symlink (via `.isSymbolicLinkKey`)
   - Remove symlink via `FileManager.removeItem()`
4. Log warnings for individual removal failures but do not throw
5. Best-effort: continues to next symlink even if one fails

**Notes:**

- Called by ViewModel before trashing a card
- Does not fail the deletion if symlink cleanup fails
- Non-symlink files with matching name are skipped (safety check)

## PlanService Implementation

**Location:** `Sources/Hieroglyphs/Services/PlanService.swift`

**Purpose:** Concrete implementation of `PlanProviding` using FileManager and Yams.

**Dependencies:**

- `FileManager` — For directory scanning, symlink operations
- `Yams` — For YAML parsing and serialization
- `FrontmatterParser` — For parsing card.md files when updating card status
- `SlugGenerator` — For generating plan slugs

**State:** Stateless. All methods read from or write to disk on every call. No caching.

**Error Handling:** Throws typed errors from `PlanError` enum. Caller (typically ViewModel) logs errors or presents them to UI.

### PlanError Enum

**Cases:**

- `invalidDirectory` — Directory does not exist or is not accessible
- `yamlParsingFailed(Error)` — YAML parsing failed (wraps underlying error)
- `directoryCreationFailed(Error)` — Directory creation failed
- `fileWriteFailed(Error)` — File write operation failed
- `planNotFound` — Plan directory or file does not exist
- `cardNotFound` — Card directory does not exist
- `symlinkCreationFailed(Error)` — Symlink creation failed

## ViewModel Integration

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

**State:**

- `@Published var plans: [Plan] = []` — Array of loaded plans
- `@Published var selectedPlan: Plan?` — Currently selected plan
- `private let planService: PlanProviding?` — Injected service

**Methods:**

- `loadPlans()` — Load plans for selected project
- `createPlan(title:number:)` — Create new plan
- `updatePlan(_:)` — Update plan metadata
- `addCardToPlan(cardSlug:planSlug:)` — Add card symlink
- `removeCardFromPlan(cardSlug:planSlug:)` — Remove card symlink
- `updatePlanStatus(plan:status:)` — Update status and cascade to cards
- `writePhasePrompt(planSlug:content:)` — Write phase prompt content

**Notes:**

- All methods call through to `planService`
- Methods reload plans after mutations to reflect changes in UI
- `updatePlanStatus()` also reloads cards when status is `done` to reflect card status changes

## Views

### PlanList

**Location:** `Sources/Hieroglyphs/Views/PlanList/PlanList.swift`

**Purpose:** Middle column view displaying plans for a project.

**Features:**

- Shows empty state when no project selected or no plans exist
- Displays list of plans with selection binding to `viewModel.selectedPlan`
- "New Plan" toolbar button (disabled when no project selected)
- Shows `NewPlanSheet` modal for creating plans
- Auto-loads plans when `selectedProject` changes

### PlanListEntry

**Location:** `Sources/Hieroglyphs/Views/PlanList/PlanListEntry.swift`

**Purpose:** Individual plan row showing number, title, status, and card count.

**Layout:**

- Status icon (circle for planning, circle.inset.filled for ready, checkmark.circle.fill for done)
- Plan title
- Subtitle: "Plan NNNN • N cards"
- Status color: gray (planning), blue (ready), green (done)

### NewPlanSheet

**Location:** `Sources/Hieroglyphs/Views/PlanList/NewPlanSheet.swift`

**Purpose:** Modal sheet for creating a new plan.

**Fields:**

- Title (required)
- Number (integer, defaults to 1)

**Actions:**

- Cancel button (dismisses sheet)
- Save button (creates plan via `viewModel.createPlan()`, disabled if title empty)

### PlanDetail

**Location:** `Sources/Hieroglyphs/Views/PlanDetail/PlanDetail.swift`

**Purpose:** Detail column view for displaying and editing a selected plan.

**Sections:**

1. **Plan Details:**
   - Status picker (updates plan status immediately)
   - Created and updated timestamps

2. **Linked Cards:**
   - List of linked cards with title, status, priority
   - "Add Card" button (shows `AddCardToPlanSheet`)
   - Context menu on each card: "Remove from Plan"
   - Dangling symlinks shown as "Missing: card-slug" with warning icon

3. **Phase Prompt:**
   - TextEditor for PHASE_PROMPT.md content
   - "Generate Phase Prompt" button (disabled, placeholder for future)

**Notes:**

- Shows empty state when no plan selected
- Phase prompt changes are written to disk immediately via `viewModel.writePhasePrompt()`

### AddCardToPlanSheet

**Location:** `Sources/Hieroglyphs/Views/PlanDetail/AddCardToPlanSheet.swift`

**Purpose:** Modal sheet for adding a card to a plan.

**Features:**

- Lists available cards (cards not already in plan)
- Shows card type, status, priority
- Selection binding
- Add button (creates symlink via `viewModel.addCardToPlan()`, disabled if no card selected)
- Cancel button (dismisses sheet)

## File Watching

Plans are monitored for external changes via `FileWatcherService`. When a `plan.yaml` or `PHASE_PROMPT.md` file changes in the `plans/` directory, the file watcher triggers `handleFileChange()` in `HieroglyphsVM`, which reloads plans for the selected project.

**Watched paths:**

- `{projectPath}/plans/**/*.yaml`
- `{projectPath}/plans/**/PHASE_PROMPT.md`

**Behavior:**

- External edits detected within ~500ms (FSEvents latency)
- Plans reloaded automatically when changes detected
- UI updates to reflect new plan metadata or phase prompt content

## Future Enhancements

**Planned additions not yet implemented:**

1. **Phase Prompt Generation:** Populate PHASE_PROMPT.md automatically from linked cards
2. **Plan Templates:** Pre-defined plan structures for common workflows
3. **Plan Reordering:** Change plan numbers and update slugs
4. **Plan Archiving:** Move completed plans to `.plans-archive/` directory
5. **Multi-Project Plans:** Plans that span multiple projects
6. **Card Dependency Tracking:** Define dependencies between cards within a plan
7. **Plan Export/Import:** Export plans to JSON or YAML for sharing
8. **Plan Number Collision Detection:** Warn or auto-increment when creating plan with existing number
