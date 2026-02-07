# Tag Reconciliation System

## Overview

The tag reconciliation system projects tags from frontmatter to macOS extended attributes, enabling native Finder and Spotlight integration. Tags defined in YAML frontmatter are written to the `com.apple.metadata:_kMDItemUserTags` extended attribute, making them visible in Finder's Get Info panel and searchable via Spotlight.

**Direction:** One-way projection from frontmatter to extended attributes (L08: Frontmatter Is Tag Source of Truth). The reverse direction is forbidden—extended attributes are never read back into frontmatter.

## Architecture

### TagReconciling Protocol

**Location:** `Sources/Hieroglyphs/Services/TagReconciling.swift`

**Purpose:** Define the service contract for tag reconciliation operations.

```swift
protocol TagReconciling {
    func reconcileTags(for tags: [String], at path: String)
}
```

**Method: reconcileTags(for:at:)**

Writes the provided tags to the file's extended attributes in plist XML format. If the tag array is empty, removes the extended attribute entirely.

**Parameters:**
- `tags` — Array of tag strings to write (empty array removes tags)
- `path` — Absolute file path to reconcile tags for

**Behavior:**
- Does not throw errors
- Logs failures internally
- Follows "do your best" philosophy
- Non-empty arrays write plist XML to extended attribute
- Empty arrays remove extended attribute

### TagReconcilerService Implementation

**Location:** `Sources/Hieroglyphs/Services/TagReconcilerService.swift`

**Purpose:** Concrete implementation using the `xattr` command-line tool.

**Implementation Details:**

#### Plist Generation

Tags are formatted as plist XML:

```xml
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
<string>work</string>
<string>planning</string>
</array>
</plist>
```

#### XML Escaping

Special characters in tag strings are escaped:
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&apos;`

#### xattr Commands

**Write tags:**
```bash
xattr -w com.apple.metadata:_kMDItemUserTags "<plist content>" <file path>
```

**Remove tags:**
```bash
xattr -d com.apple.metadata:_kMDItemUserTags <file path>
```

#### Error Handling

- xattr command failures are logged to console
- Errors do not throw (do your best philosophy)
- Failed reconciliation does not block file operations

### Environment Key

**Location:** `Sources/Hieroglyphs/Services/TagReconcilerServiceEnvironmentKey.swift`

Provides SwiftUI environment injection:

```swift
private struct TagReconcilerServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: TagReconciling = TagReconcilerService()
}

extension EnvironmentValues {
    var tagReconciler: TagReconciling {
        get { self[TagReconcilerServiceKey.self] }
        set { self[TagReconcilerServiceKey.self] = newValue }
    }
}
```

## Integration with File Watcher

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

### Automatic Reconciliation

Tag reconciliation triggers automatically when files change:

1. FileWatcherService detects file modification
2. HieroglyphsVM.handleFileChange(url:) called
3. ViewModel reloads project or card from disk
4. ViewModel calls reconciler with updated tags

### Implementation Flow

```swift
private func handleFileChange(url: URL) {
    if path.contains("/project.md") {
        loadProjects()
        reconcileProjectTags(at: path)
    } else if path.contains("/cards/") || path.contains("/card.md") {
        if let selectedProject, path.contains("/\(selectedProject.slug)/") {
            loadCards()
        }
        reconcileCardTags(at: path)
    }
}
```

### Helper Methods

**reconcileProjectTags(at:)**
- Extracts project from path
- Reads tags from frontmatter
- Calls reconciler with project tags

**reconcileCardTags(at:)**
- Extracts card from path
- Reads tags from frontmatter
- Calls reconciler with card tags

**extractProjectFromPath(_:)**
- Loads all projects from workspace
- Finds project matching path slug

**extractCardFromPath(_:)**
- Extracts project from path
- Loads all cards for project
- Finds card matching path slug

## Testing

### Unit Tests

**Location:** `Tests/HieroglyphsTests/TagReconcilerServiceTests.swift`

**Coverage:**
1. **testReconcileNonEmptyTagsWritesPlist:** Verify tags written to extended attributes
2. **testReconcileEmptyTagsRemovesAttribute:** Verify empty array removes attribute
3. **testGeneratedPlistIsValidXML:** Verify plist format is valid and parseable
4. **testXMLSpecialCharactersEscaped:** Verify special characters escaped correctly

**Test Strategy:**
- Use temporary files in FileManager.temporaryDirectory
- Write tags via service
- Read back via `xattr -p` command
- Parse plist with PropertyListSerialization
- Verify tag arrays match expected values

### Integration Tests

**Location:** `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`

**Coverage:**
1. **testProjectChangeTriggersTagReconciliation:** Verify reconciler called on project.md change
2. **testCardChangeTriggersTagReconciliation:** Verify reconciler called on card.md change
3. **testTagReconciliationNotCalledWhenReconcilerNil:** Verify graceful handling when reconciler is nil

**Test Strategy:**
- Inject MockTagReconciler via ViewModel init
- Simulate file changes via MockFileWatcher
- Verify reconciler called with correct tags and paths

### Manual Verification

**Verification Steps:**

1. **Create project with tags:**
   ```yaml
   tags:
     - work
     - planning
   ```

2. **Verify via mdls:**
   ```bash
   mdls /path/to/project.md | grep kMDItemUserTags
   ```
   Expected output:
   ```
   kMDItemUserTags = (
       work,
       planning
   )
   ```

3. **Verify in Finder:**
   - Right-click file → Get Info
   - Tags section shows colored tags
   - Tags match frontmatter values

4. **Test external edits:**
   - Edit frontmatter in text editor
   - Save file
   - Extended attributes update automatically within ~500ms
   - Tags update in Finder without manual refresh

## Constraint: L08 Enforcement

**Law L08:** Frontmatter Is Tag Source of Truth

**One-Way Projection:**
- Tags flow FROM frontmatter TO extended attributes
- NEVER from extended attributes to frontmatter

**Implications:**
- User changes tags in Finder → Silently overwritten on next reconciliation
- This is correct per L08 but may surprise users initially
- Documentation should make this clear to users

**Why One-Way:**
- Frontmatter is version-controlled and portable
- Extended attributes are opaque and lost on file copy
- Frontmatter is the authoritative source

## Future Enhancements

### Native Swift APIs

**Current:** Uses `xattr` command-line tool via Process

**Future:** Replace with native extended attribute APIs for better performance:
```swift
import Foundation
setxattr(path, "com.apple.metadata:_kMDItemUserTags", plistData, flags)
```

**Benefits:**
- No Process overhead
- Direct API access
- Better error handling

### Batch Reconciliation

**Current:** Single-file reconciliation on change

**Future:** Batch reconcile entire workspace:
```swift
func reconcileWorkspace(at path: String)
```

**Use Cases:**
- Initial workspace setup
- Migration from older versions
- Manual "sync all" operation

### Manual Reconciliation UI

**Current:** Automatic only via file watcher

**Future:** User-triggered reconciliation:
- Menu command: File → Reconcile Tags
- Keyboard shortcut
- Context menu on project/card

### Conflict Detection

**Current:** No conflict detection

**Future:** Detect when extended attributes diverge from frontmatter:
- Warn user when tags manually changed in Finder
- Option to override or preserve Finder changes
- Requires careful design to respect L08

### Performance Optimization

**Current:** Every file change triggers reconciliation

**Future:**
- Debounce reconciliation calls
- Only reconcile if tags actually changed
- Batch reconciliation for rapid successive changes

## Related Documentation

- **File Watching:** `.ushabti/docs/file-watching.md`
- **Models:** `.ushabti/docs/models.md`
- **Architecture:** `.ushabti/docs/architecture.md`
- **Testing:** `.ushabti/docs/testing.md`
