# Domain Models

## Overview

Domain models are plain Swift structs and enums representing workspace entities. They conform to standard protocols (`Codable`, `Identifiable`, `Equatable`, `Hashable`) but have no business logic, no I/O, and no framework dependencies beyond Foundation.

Models support L09 (Sandi Metz: plain data types separate from persistence) and L04 (No SwiftData/Core Data).

## WorkspaceConfig

**Location:** `Sources/Hieroglyphs/Models/WorkspaceConfig.swift`

**Purpose:** Represents the workspace configuration stored in `~/.hieroglyphs/config.yaml`.

**Fields:**
- `workspacePath: String` — Absolute path to the workspace directory containing projects

**Conformances:** `Codable`, `Equatable`

**Notes:** This is a simple wrapper struct holding the workspace location. It is loaded via WorkspaceService and cached in HieroglyphsVM.

## Project

**Location:** `Sources/Hieroglyphs/Models/Project.swift`

**Purpose:** Represents a project with metadata and timestamps.

**Fields:**
- `id: UUID` — Unique identifier for the project
- `title: String` — Human-readable project title
- `description: String` — Brief project description
- `tags: [String]` — Array of tag strings for categorization
- `created: Date` — ISO8601 timestamp of project creation
- `updated: Date` — ISO8601 timestamp of last update
- `slug: String` — Filesystem-safe slug used as directory name (e.g., `my-project`)
- `sourceDirectory: String?` — Optional path to project source directory (typically `.ushabti/phases/` directory)

**Conformances:** `Identifiable`, `Codable`, `Equatable`, `Hashable`

**Notes:**
- `slug` is derived from `title` via `SlugGenerator` and used as the project directory name
- Projects are stored in `{workspacePath}/{slug}/project.md` with YAML frontmatter
- `id` is a UUID string in frontmatter, used for stable identity independent of title changes
- `tags` are stored as YAML arrays and projected one-way to extended attributes (L08)

**Example frontmatter:**

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: My Project
description: A sample project
tags:
  - work
  - planning
created: 2026-01-15T10:30:00Z
updated: 2026-01-20T14:22:00Z
slug: my-project
source_directory: /Users/alice/code/my-project/.ushabti/phases
---
```

Note: `source_directory` is optional and only appears in frontmatter when set.

## Card

**Location:** `Sources/Hieroglyphs/Models/Card.swift`

**Purpose:** Represents a work item with type, status, priority, and markdown body.

**Fields:**
- `id: UUID` — Unique identifier for the card
- `title: String` — Human-readable card title
- `type: CardType` — Card type (task, bug, feature, note)
- `status: CardStatus` — Workflow state (backlog, todo, in-progress, done, archived)
- `priority: Priority` — Priority level (low, medium, high, critical)
- `tags: [String]` — Array of tag strings for categorization
- `created: Date` — ISO8601 timestamp of card creation
- `updated: Date` — ISO8601 timestamp of last update
- `slug: String` — Filesystem-safe slug used as directory name (e.g., `implement-feature`)
- `body: String` — Markdown content below frontmatter

**Conformances:** `Identifiable`, `Codable`, `Equatable`

**Notes:**
- `slug` is derived from `title` via `SlugGenerator` and used as the card directory name
- Cards are stored in `{workspacePath}/{projectSlug}/cards/{cardSlug}/card.md`
- `body` contains the markdown content below the frontmatter delimiter
- Card enums (`type`, `status`, `priority`) are stored as raw strings in frontmatter
- `tags` are stored as YAML arrays and projected one-way to extended attributes (L08)

**Example frontmatter:**

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

This is the markdown body content describing the card.

## Details

Additional markdown content here.
```

## CardType

**Location:** `Sources/Hieroglyphs/Models/CardType.swift`

**Purpose:** Enum representing the category of a card.

**Cases:**
- `task` — A general work item
- `bug` — A defect or issue to fix
- `feature` — A new capability to implement
- `note` — A documentation or informational card

**Conformances:** `String`, `Codable`, `CaseIterable`

**Notes:**
- Raw values are lowercase strings matching enum case names
- Stored in frontmatter `type` field as raw string (e.g., `type: feature`)
- `CaseIterable` enables UI pickers to list all valid types

## CardStatus

**Location:** `Sources/Hieroglyphs/Models/CardStatus.swift`

**Purpose:** Enum representing the workflow state of a card.

**Cases:**
- `backlog` — Not yet scheduled for work
- `todo` — Scheduled but not started
- `inProgress` — Currently being worked on (stored as `in-progress`)
- `done` — Completed
- `archived` — Archived or obsolete

**Conformances:** `String`, `Codable`, `CaseIterable`

**Notes:**
- Raw values are lowercase kebab-case strings (e.g., `in-progress` for `inProgress`)
- Stored in frontmatter `status` field as raw string (e.g., `status: in-progress`)
- Card counts in sidebar are grouped by status to show workflow progress

## Priority

**Location:** `Sources/Hieroglyphs/Models/Priority.swift`

**Purpose:** Enum representing the priority level of a card.

**Cases:**
- `low` — Low priority
- `medium` — Medium priority (default)
- `high` — High priority
- `critical` — Critical priority requiring immediate attention

**Conformances:** `String`, `Codable`, `CaseIterable`

**Notes:**
- Raw values are lowercase strings matching enum case names
- Stored in frontmatter `priority` field as raw string (e.g., `priority: high`)
- Default priority for new cards is `medium` (handled by UI, not model)

## Model Relationships

- **WorkspaceConfig → Projects:** Workspace path points to directory containing project subdirectories
- **Project → Cards:** Each project has a `cards/` subdirectory containing card subdirectories
- **Project.slug and Card.slug:** Used to construct filesystem paths

**Directory structure:**

```
{workspacePath}/
  {project-slug}/
    project.md          ← Project frontmatter
    cards/
      {card-slug}/
        card.md         ← Card frontmatter + body
```

## Date Handling

Dates are stored as ISO8601 strings in frontmatter and parsed to `Date` objects by WorkspaceService. The `ISO8601DateFormatter` is used for encoding and decoding.

**Format:** `YYYY-MM-DDTHH:MM:SSZ` (e.g., `2026-01-15T10:30:00Z`)

## Unknown Field Preservation (L02)

WorkspaceService preserves unknown frontmatter fields when reading and writing files. Models only define known fields. Extra fields in frontmatter are round-tripped unchanged, supporting L02 (Opinionated on Write, Laissez-Faire on Read).

Example: If a project.md file contains a custom `owner: alice` field, WorkspaceService preserves it even though `Project` model does not define an `owner` property.
