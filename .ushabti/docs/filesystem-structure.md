# Filesystem Structure

## Overview

Hieroglyphs stores all data as plain text markdown files with YAML frontmatter in a workspace directory. The filesystem is the single source of truth per L01, enabling transparency, version control, and integration with external tools.

This document describes the on-disk file and directory structure, file formats, and naming conventions.

## Workspace Configuration

**Location:** `~/.hieroglyphs/config.yaml`

**Purpose:** Store workspace path configuration.

**Format:** YAML file with `workspacePath` field.

**Example:**

```yaml
workspacePath: /Users/alice/Hieroglyphs
```

**Notes:**
- Config file is loaded by WorkspaceService on app launch
- If config does not exist, app shows empty state (workspace path nil)
- Config directory (`~/.hieroglyphs`) is created during workspace initialization

## Workspace Directory Structure

**Location:** Path specified in `~/.hieroglyphs/config.yaml`

**Structure:**

```
{workspacePath}/
├── CLAUDE.md                 # AI assistant instructions (generated)
├── AGENT.md                  # Agent workflow instructions (generated)
├── project-slug-1/           # Project directory (slug from title)
│   ├── project.md            # Project frontmatter
│   ├── cards/                # Cards subdirectory
│   │   ├── card-slug-1/      # Card directory (slug from title)
│   │   │   └── card.md       # Card frontmatter + body
│   │   └── card-slug-2/
│   │       └── card.md
│   └── plans/                # Plans subdirectory
│       └── 0001-plan-slug/   # Plan directory (number + slug)
│           ├── plan.yaml     # Plan metadata
│           ├── PHASE_PROMPT.md  # Phase prompt content
│           ├── card-slug-1   # Symlink → ../../cards/card-slug-1/
│           └── card-slug-2   # Symlink → ../../cards/card-slug-2/
└── project-slug-2/
    ├── project.md
    └── cards/
        └── card-slug-3/
            └── card.md
```

**Notes:**
- Project directories are named with slugs (lowercase, hyphen-separated, alphanumeric)
- Each project contains `project.md` file with frontmatter
- Cards live in `{project}/cards/{card-slug}/card.md`
- Card directories are nested (directory per card, not flat file structure)
- Plans live in `{project}/plans/{NNNN}-{slug}/` with plan.yaml, PHASE_PROMPT.md, and card symlinks
- Plan symlinks are relative: `../../cards/{card-slug}/`

## Project Files

### project.md

**Location:** `{workspacePath}/{project-slug}/project.md`

**Purpose:** Store project metadata in YAML frontmatter.

**Format:** Markdown file with YAML frontmatter (no body content).

**Frontmatter Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID string | Yes | Unique identifier |
| `title` | String | Yes | Human-readable title |
| `slug` | String | Yes | Filesystem-safe slug (must match directory name) |
| `description` | String | No | Project description (defaults to `""`) |
| `tags` | Array of strings | No | Tag list (defaults to `[]`) |
| `created` | ISO8601 date string | No | Creation timestamp (defaults to current date) |
| `updated` | ISO8601 date string | No | Last update timestamp (defaults to current date) |

**Example:**

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: My Project
description: A sample project for demonstration
tags:
  - work
  - planning
created: 2026-01-15T10:30:00Z
updated: 2026-01-20T14:22:00Z
slug: my-project
---
```

**Notes:**
- No body content below frontmatter (future: may add project README)
- `slug` field must match directory name exactly
- Unknown fields are preserved per L02 (e.g., custom `owner` or `priority` fields)

## Card Files

### card.md

**Location:** `{workspacePath}/{project-slug}/cards/{card-slug}/card.md`

**Purpose:** Store card metadata in frontmatter and markdown content in body.

**Format:** Markdown file with YAML frontmatter and body content.

**Frontmatter Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID string | Yes | Unique identifier |
| `title` | String | Yes | Human-readable title |
| `slug` | String | Yes | Filesystem-safe slug (must match directory name) |
| `type` | String enum | No | Card type: `task`, `bug`, `feature`, `note` (defaults to `task`) |
| `status` | String enum | No | Card status: `backlog`, `todo`, `in-progress`, `done`, `archived` (defaults to `backlog`) |
| `priority` | String enum | No | Priority level: `low`, `medium`, `high`, `critical` (defaults to `medium`) |
| `tags` | Array of strings | No | Tag list (defaults to `[]`) |
| `created` | ISO8601 date string | No | Creation timestamp (defaults to current date) |
| `updated` | ISO8601 date string | No | Last update timestamp (defaults to current date) |

**Body:** Markdown content below frontmatter delimiter.

**Example:**

```yaml
---
id: 987fcdeb-51a2-43f1-8d0e-123456789abc
title: Implement Feature
type: feature
status: in-progress
priority: high
tags:
  - backend
  - api
created: 2026-01-16T09:00:00Z
updated: 2026-01-17T11:45:00Z
slug: implement-feature
---

This is the card body with markdown content describing the feature.

## Requirements

- Requirement 1
- Requirement 2

## Implementation Notes

Additional markdown content here with **formatting**, _emphasis_, and [links](https://example.com).
```

**Notes:**
- Body content is freeform markdown (headings, lists, code blocks, links, images, etc.)
- `slug` field must match directory name exactly
- Unknown fields are preserved per L02
- Empty body is allowed (card may have only frontmatter)

## Plan Files

### plan.yaml

**Location:** `{workspacePath}/{project-slug}/plans/{plan-slug}/plan.yaml`

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
- Unknown fields are preserved per L02
- Linked cards are represented as symlinks in the plan directory, not stored in plan.yaml

### PHASE_PROMPT.md

**Location:** `{workspacePath}/{project-slug}/plans/{plan-slug}/PHASE_PROMPT.md`

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
```

**Notes:**
- Initially empty when plan is created
- Editable in Hieroglyphs PlanDetail view
- Used by Ushabti Scribe to generate phase plans (future enhancement)

### Card Symlinks

Plans use relative symlinks to link to cards. Each symlink in the plan directory points to a card directory in the project's cards/ subdirectory.

**Format:** `{plan-directory}/{card-slug}` → `../../cards/{card-slug}/`

**Example:**

```
/Users/alice/Hieroglyphs/my-project/plans/0001-initial-setup/card-1
  → ../../cards/card-1/
```

**Notes:**
- Symlinks are relative (two levels up, then into cards directory)
- Enables workspace portability (moving workspace preserves symlinks)
- Dangling symlinks (card deleted) are tolerated and shown as "Missing" in UI
- Card deletion does not automatically remove symlinks from plans

## Instructional Files

### CLAUDE.md

**Location:** `{workspacePath}/CLAUDE.md`

**Purpose:** Document workspace structure for AI assistants (Claude, GPT, etc.).

**Content:** Markdown file explaining workspace structure, frontmatter schema, and editing guidelines for LLMs.

**Generated by:** `WorkspaceService.initializeWorkspaceFiles()`

**Example excerpt:**

```markdown
# CLAUDE.md

This workspace is managed by Hieroglyphs, a markdown-based project management tool.

## For AI Assistants

- All project data lives in plain text markdown files with YAML frontmatter
- Projects are in top-level directories with `project.md` files
- Cards are in `cards/` subdirectories with `card.md` files
- Edit files directly — changes are detected automatically
- Preserve unknown frontmatter fields when updating files
```

### AGENT.md

**Location:** `{workspacePath}/AGENT.md`

**Purpose:** Document workspace structure for agent workflows (Ushabti, scripts, etc.).

**Content:** Markdown file explaining agent instructions, frontmatter field definitions, and date formats.

**Generated by:** `WorkspaceService.initializeWorkspaceFiles()`

**Example excerpt:**

```markdown
# AGENT.md

This workspace contains Hieroglyphs projects and cards.

## Agent Instructions

When working with this workspace:

1. Read project.md files to understand project structure
2. Read card.md files to understand tasks and content
3. Update frontmatter fields to change metadata
4. Add markdown content below frontmatter for card bodies
5. Always preserve unknown frontmatter fields
6. Use ISO8601 format for dates (YYYY-MM-DDTHH:MM:SSZ)
```

**Notes:**
- These files are informational only (not read by Hieroglyphs app)
- They enable external tools and LLMs to understand workspace structure
- Files are generated during workspace initialization and not updated by app

## File Naming Conventions

### Slugs

**Purpose:** Convert human-readable titles to filesystem-safe directory names.

**Rules:**
1. Lowercase only
2. Replace spaces with hyphens
3. Keep only letters, numbers, and hyphens
4. Collapse multiple consecutive hyphens to single hyphen
5. Trim leading/trailing hyphens

**Examples:**

| Title | Slug |
|-------|------|
| `My Project` | `my-project` |
| `Bug #42: Fix crash` | `bug-42-fix-crash` |
| `Feature  Request!!` | `feature-request` |

**Notes:**
- Slugs are generated via `SlugGenerator.generateSlug(from:)`
- Slugs must match directory names exactly
- Slug collisions are not handled (future enhancement)

### File Names

**Fixed names:**
- `project.md` — Project file (always this name)
- `card.md` — Card file (always this name)
- `config.yaml` — Workspace config (always this name)

**Directory names:**
- Project directories: `{slug}` (e.g., `my-project`)
- Card directories: `{slug}` (e.g., `implement-feature`)
- Cards subdirectory: `cards` (always this name)

## Date Format

**Format:** ISO8601 with UTC timezone

**Pattern:** `YYYY-MM-DDTHH:MM:SSZ`

**Example:** `2026-01-15T10:30:00Z`

**Notes:**
- Dates are stored as strings in frontmatter
- Parsed via `ISO8601DateFormatter` in Swift
- Always UTC timezone (trailing `Z`)
- No timezone offsets (e.g., no `-08:00`)

## Unknown Field Preservation (L02)

**Purpose:** Allow users and external tools to extend frontmatter beyond app-defined fields.

**Behavior:**
- WorkspaceService reads all frontmatter fields into dictionary
- On update, service merges known fields into existing dictionary
- Unknown fields are preserved unchanged
- Service serializes entire dictionary back to file

**Example:**

Original `project.md`:

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: My Project
owner: alice
custom_priority: urgent
---
```

After updating title via app:

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: Updated Project Title
owner: alice
custom_priority: urgent
updated: 2026-01-20T14:22:00Z
---
```

`owner` and `custom_priority` fields are preserved even though `Project` model does not define them.

## Version Control Integration

**Recommended:** Use Git to version control the workspace directory.

**Benefits:**
- Track all changes to projects and cards
- Collaborate with team via Git workflows (branches, pull requests)
- Integrate with CI/CD pipelines
- Sync workspace across machines

**Gitignore recommendations:**

```
# macOS
.DS_Store

# Hieroglyphs config (local only)
~/.hieroglyphs/

# Temporary files
*.swp
*.tmp
```

**Notes:**
- Workspace directory should be Git repository root
- Config file at `~/.hieroglyphs/config.yaml` is user-specific (not committed)
- All project and card files are plain text (Git-friendly)

## External Tool Integration

**Supported workflows:**

1. **LLMs (Claude, GPT, etc.):** Read `CLAUDE.md`, edit project/card files directly
2. **Text Editors:** Open card.md files in any editor (VS Code, Vim, etc.)
3. **Command-Line Tools:** Parse frontmatter with Yams, jq, or similar tools
4. **Scripts:** Read/write card files to automate workflows
5. **CI/CD:** Run tests, linting, or validation on workspace files

**Notes:**
- Changes made externally are first-class (L05)
- App detects external changes via FSEvents file watching with ~500ms latency
- Frontmatter is standard YAML (parseable by any YAML library)

## File System Requirements

**Supported Filesystems:** APFS, HFS+ (macOS filesystems)

**Case Sensitivity:** Slugs are lowercase, but filesystem may be case-insensitive (macOS default)

**Character Encoding:** UTF-8 for all files

**Permissions:** Workspace directory must be readable and writable by app

**Limitations:**
- Maximum path length: 1024 characters (macOS limit)
- Maximum filename length: 255 characters (macOS limit)
- Reserved characters: None (slugs avoid problematic characters)

## Future Enhancements

**Planned additions not yet implemented:**

1. **Hidden Directories:** `.cards/` for archived cards (similar to Git's `.git/`)
2. **Attachments:** `{card-slug}/attachments/` subdirectory for images, PDFs, etc.
3. **Templates:** `.templates/` directory for project and card templates
4. **Indexes:** `.indexes/` directory for Spotlight metadata or custom indexes
5. **Backups:** Automatic backups to `.backups/` directory on significant changes
