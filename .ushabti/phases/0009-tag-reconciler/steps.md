# Implementation Steps

## S001: Define TagReconciling Protocol

**Intent:** Establish the service contract for tag reconciliation operations.

**Work:**
- Create `Sources/Hieroglyphs/Services/TagReconciling.swift`
- Define protocol with single method: `reconcileTags(for:at:)` accepting tag array and file path
- Add protocol documentation describing one-way projection behavior
- Document that method does not throw (logs errors internally)

**Done when:**
- Protocol file exists with documented method signature
- Protocol follows same pattern as FileWatching and WorkspaceProviding

## S002: Implement TagReconcilerService

**Intent:** Create concrete implementation that writes tags to extended attributes via xattr.

**Work:**
- Create `Sources/Hieroglyphs/Services/TagReconcilerService.swift`
- Implement `TagReconciling` protocol
- Implement `reconcileTags(for:at:)` method
- Generate plist XML format for tag array
- Execute `xattr -w com.apple.metadata:_kMDItemUserTags {plist} {path}` command
- Handle empty tag arrays by removing extended attribute with `xattr -d`
- Log errors on xattr command failure (do not throw)

**Done when:**
- Service class exists and conforms to protocol
- Generates valid plist XML for tag arrays
- Executes xattr commands correctly
- Handles empty arrays by removing attribute

## S003: Create Environment Key

**Intent:** Enable dependency injection via SwiftUI Environment.

**Work:**
- Create `Sources/Hieroglyphs/Services/TagReconcilerServiceEnvironmentKey.swift`
- Define EnvironmentKey with default value
- Add EnvironmentValues extension for `.tagReconciler` property
- Follow same pattern as WorkspaceServiceEnvironmentKey and FileWatcherServiceEnvironmentKey

**Done when:**
- Environment key file exists
- Extension provides `.tagReconciler` accessor
- Pattern matches existing service environment keys

## S004: Integrate with FileWatcherService

**Intent:** Trigger tag reconciliation automatically when files change.

**Work:**
- Modify `HieroglyphsVM.handleFileChange(url:)` method
- After reloading projects or cards, call tag reconciler
- For project changes: reconcile tags for the changed project file
- For card changes: reconcile tags for the changed card file
- Inject TagReconcilerService via environment in HieroglyphsVM

**Done when:**
- File changes trigger reconciliation after reload
- Projects and cards have tags written to extended attributes on change
- ViewModel has tagReconciler injected and uses it

## S005: Inject Service in App

**Intent:** Provide TagReconcilerService instance at app root.

**Work:**
- Modify `Sources/Hieroglyphs/App.swift`
- Create `TagReconcilerService()` instance
- Inject via `.environment(\.tagReconciler, service)` modifier
- Follow same pattern as workspace and file watcher services

**Done when:**
- App.swift instantiates and injects TagReconcilerService
- Service available throughout view hierarchy

## S006: Write TagReconcilerService Tests

**Intent:** Verify tag reconciliation writes correct extended attributes.

**Work:**
- Create `Tests/HieroglyphsTests/TagReconcilerServiceTests.swift`
- Test reconciling non-empty tag array writes plist to extended attribute
- Test reconciling empty array removes extended attribute
- Test generated plist format is valid XML
- Use temporary files for testing
- Verify xattr commands executed correctly (check extended attributes on temp files)

**Done when:**
- Test file exists with comprehensive coverage
- All test cases pass
- Tests verify extended attributes on real temporary files

## S007: Write Integration Tests

**Intent:** Verify end-to-end tag projection from frontmatter to extended attributes.

**Work:**
- Add tests to `HieroglyphsVMTests.swift`
- Test that file changes trigger tag reconciliation
- Mock TagReconciling protocol in tests
- Verify reconciler called with correct tags and paths
- Test both project and card file changes

**Done when:**
- Integration tests exist
- Tests verify reconciler called on file changes
- Tests cover both project and card scenarios

## S008: Manual Verification

**Intent:** Confirm tags appear correctly in Finder and Spotlight.

**Work:**
- Build and run the app
- Create a test project with tags `["work", "planning"]`
- Verify via terminal: `mdls {projectPath}/project.md | grep kMDItemUserTags`
- Verify tags appear in Finder Get Info panel
- Create a card with tags `["urgent", "bug"]`
- Verify card tags via mdls and Finder
- Edit tags in frontmatter externally (text editor)
- Verify extended attributes update automatically

**Done when:**
- Tags visible via mdls command
- Tags visible in Finder Get Info
- External edits trigger reconciliation
- Tags update correctly in Finder

## S009: Update Documentation

**Intent:** Document the tag reconciliation system.

**Work:**
- Create `.ushabti/docs/tag-reconciliation.md`
- Document TagReconciling protocol and TagReconcilerService
- Document integration with file watcher
- Document one-way projection constraint (L08)
- Document extended attribute format and xattr usage
- Document testing approach

**Done when:**
- Documentation file exists
- Covers protocol, service, integration, and constraints
- Includes examples of mdls verification
