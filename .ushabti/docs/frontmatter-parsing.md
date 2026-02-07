# Frontmatter Parsing and Slug Generation

## Overview

Hieroglyphs uses YAML frontmatter in markdown files to store structured metadata. The `FrontmatterParser` utility parses and serializes markdown files with frontmatter, while `SlugGenerator` creates filesystem-safe directory names from titles.

**Location:** `Sources/Hieroglyphs/Utilities/`

These utilities support L02 (Preserve Unknown Fields) and L01 (Filesystem as Source of Truth).

## FrontmatterParser

**Purpose:** Parse and serialize markdown files with YAML frontmatter.

**Dependencies:** Foundation, Yams

**Methods:**
- `parse(_:)` — Parse markdown string into frontmatter dictionary and body
- `serialize(frontmatter:body:)` — Serialize frontmatter and body into markdown string

### parse(_:)

**Signature:** `static func parse(_ markdown: String) throws -> (frontmatter: [String: Any], body: String)`

**Purpose:** Parse markdown content with YAML frontmatter into structured data.

**Parameters:**
- `markdown` — The markdown content to parse (may or may not have frontmatter)

**Returns:** Tuple containing:
- `frontmatter` — Dictionary of frontmatter fields (empty if no frontmatter)
- `body` — Markdown body content (may be empty)

**Throws:**
- `ParserError.invalidFormat` if frontmatter delimiters are malformed
- `ParserError.yamlParsingFailed(Error)` if YAML content is invalid

**Behavior:**

1. Split markdown into lines
2. Check if first line is `---` (frontmatter delimiter)
   - If no frontmatter, return `([:], originalMarkdown)`
3. Find closing `---` delimiter
   - If not found, throw `invalidFormat`
4. Extract lines between delimiters as YAML string
5. Parse YAML via `Yams.load(yaml:)` into `[String: Any]`
   - If parsing fails, throw `yamlParsingFailed`
6. Extract remaining lines as body
7. Return tuple

**Example:**

```swift
let markdown = """
---
title: My Project
tags:
  - work
  - planning
---

This is the body content.
"""

let parsed = try FrontmatterParser.parse(markdown)
// parsed.frontmatter = ["title": "My Project", "tags": ["work", "planning"]]
// parsed.body = "\nThis is the body content.\n"
```

**Notes:**
- If markdown has no frontmatter (does not start with `---`), returns empty frontmatter dictionary and original markdown as body
- Body preserves leading/trailing whitespace (caller may trim if desired)
- Frontmatter dictionary uses `Any` type to preserve unknown field types

### serialize(frontmatter:body:)

**Signature:** `static func serialize(frontmatter: [String: Any], body: String) throws -> String`

**Purpose:** Serialize frontmatter dictionary and body into markdown string with YAML frontmatter.

**Parameters:**
- `frontmatter` — Dictionary of frontmatter fields to serialize
- `body` — Markdown body content

**Returns:** Complete markdown string with frontmatter delimiters.

**Throws:**
- `ParserError.yamlSerializationFailed(Error)` if YAML serialization fails

**Behavior:**

1. If frontmatter is empty, return body as-is (no delimiters)
2. Serialize frontmatter dictionary via `Yams.dump(object:allowUnicode:)`
3. Trim whitespace from YAML string
4. Construct markdown: `---\n{yaml}\n---\n{body}`
5. Return markdown string

**Example:**

```swift
let frontmatter: [String: Any] = [
    "title": "My Project",
    "tags": ["work", "planning"]
]
let body = "This is the body content."

let markdown = try FrontmatterParser.serialize(frontmatter: frontmatter, body: body)
// markdown = "---\ntitle: My Project\ntags:\n  - work\n  - planning\n---\nThis is the body content."
```

**Notes:**
- Uses `allowUnicode: true` to preserve non-ASCII characters in YAML
- If frontmatter is empty, returns body without delimiters
- Body is appended as-is (no trimming or modification)

### Unknown Field Preservation

**Purpose:** Support L02 (Preserve Unknown Fields) by round-tripping unknown frontmatter fields unchanged.

**How it works:**

1. `parse(_:)` extracts frontmatter as `[String: Any]` dictionary (all fields preserved)
2. WorkspaceService merges known fields into frontmatter dictionary
3. `serialize(frontmatter:body:)` serializes entire dictionary (including unknown fields)

**Example:**

Existing `project.md`:

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: My Project
owner: alice
custom_field: some_value
---
```

After updating title via WorkspaceService:

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: Updated Project Title
owner: alice
custom_field: some_value
updated: 2026-01-20T14:22:00Z
---
```

`owner` and `custom_field` are preserved even though `Project` model does not define them.

## SlugGenerator

**Purpose:** Generate filesystem-safe slugs from title strings.

**Dependencies:** Foundation

**Method:**
- `generateSlug(from:)` — Convert title to slug

### generateSlug(from:)

**Signature:** `static func generateSlug(from title: String) -> String`

**Purpose:** Convert a title string to a lowercase, hyphen-separated, alphanumeric slug suitable for directory names.

**Parameters:**
- `title` — The title to convert (may contain spaces, punctuation, non-ASCII characters)

**Returns:** Filesystem-safe slug string (lowercase alphanumeric + hyphens).

**Behavior:**

1. Convert title to lowercase
2. Replace spaces with hyphens
3. Filter characters: keep only letters, numbers, and hyphens
4. Collapse multiple consecutive hyphens into single hyphens
5. Trim leading/trailing hyphens
6. Return slug

**Examples:**

| Title | Slug |
|-------|------|
| `My Project` | `my-project` |
| `Bug #42: Fix crash` | `bug-42-fix-crash` |
| `Feature  Request!!` | `feature-request` |
| `Café Menu` | `caf-menu` |
| `---test---` | `test` |

**Notes:**
- Non-ASCII characters are removed (e.g., `é` becomes empty string)
- Punctuation is removed except hyphens
- Multiple spaces or punctuation collapse to single hyphen
- Result is always lowercase
- Empty titles return empty slug (caller should validate)

**Slug Uniqueness:**

SlugGenerator does NOT guarantee uniqueness. If two projects have the same title (or titles that collapse to the same slug), they will produce the same slug. WorkspaceService does NOT handle slug collision. Caller (ViewModel) should validate uniqueness before calling `createProject` or `createCard`.

Future phases may add collision detection and auto-incrementing (e.g., `my-project-2`).

## YAML Format

### Project Frontmatter

**File:** `{workspacePath}/{slug}/project.md`

**Required fields:**
- `id` — UUID string
- `title` — String
- `slug` — String (must match directory name)

**Optional fields:**
- `description` — String (defaults to `""`)
- `tags` — Array of strings (defaults to `[]`)
- `created` — ISO8601 date string (defaults to current date)
- `updated` — ISO8601 date string (defaults to current date)

**Example:**

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
---
```

### Card Frontmatter

**File:** `{workspacePath}/{projectSlug}/cards/{slug}/card.md`

**Required fields:**
- `id` — UUID string
- `title` — String
- `slug` — String (must match directory name)

**Optional fields:**
- `type` — String enum (task, bug, feature, note; defaults to `task`)
- `status` — String enum (backlog, todo, in-progress, done, archived; defaults to `backlog`)
- `priority` — String enum (low, medium, high, critical; defaults to `medium`)
- `tags` — Array of strings (defaults to `[]`)
- `created` — ISO8601 date string (defaults to current date)
- `updated` — ISO8601 date string (defaults to current date)

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

This is the card body with markdown content.

## Details

Additional information here.
```

### Workspace Config

**File:** `~/.hieroglyphs/config.yaml`

**Required fields:**
- `workspacePath` — Absolute path to workspace directory

**Example:**

```yaml
workspacePath: /Users/alice/Hieroglyphs
```

## Date Format

Dates are stored as ISO8601 strings in frontmatter.

**Format:** `YYYY-MM-DDTHH:MM:SSZ`

**Example:** `2026-01-15T10:30:00Z`

**Parsing:** `ISO8601DateFormatter` (Foundation)

**Encoding:** `ISO8601DateFormatter.string(from:)`

**Notes:** UTC timezone always used (trailing `Z`). No timezone offsets.

## Error Handling

### FrontmatterParser.ParserError

**Cases:**
- `invalidFormat` — Frontmatter delimiters are malformed (missing closing `---`)
- `yamlParsingFailed(Error)` — YAML content is invalid (wraps Yams error)
- `yamlSerializationFailed(Error)` — YAML serialization failed (wraps Yams error)

**Handling:** WorkspaceService catches these errors and wraps them in `WorkspaceError.yamlParsingFailed` or logs warnings for malformed files.

## Testing

**Files:**
- `FrontmatterParserTests.swift` — Tests parse/serialize round-trips, edge cases, error handling
- `SlugGeneratorTests.swift` — Tests slug generation with various input patterns

**Coverage:**
- Parse markdown with and without frontmatter
- Serialize frontmatter and body
- Round-trip preservation of unknown fields
- Slug generation with spaces, punctuation, non-ASCII, edge cases
- Error cases (malformed frontmatter, invalid YAML)
