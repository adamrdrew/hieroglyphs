import XCTest
@testable import Hieroglyphs

final class DocsServiceTests: XCTestCase {
    private var fixtureRoot: URL!
    private var docsURL: URL!
    private var fileManager: FileManager!
    private var service: DocsService!

    override func setUp() {
        super.setUp()
        fileManager = FileManager.default
        service = DocsService(fileManager: fileManager)

        let tempDir = fileManager.temporaryDirectory
        fixtureRoot = tempDir.appendingPathComponent(UUID().uuidString)
        docsURL = fixtureRoot.appendingPathComponent("docs")

        try? fileManager.createDirectory(
            at: fixtureRoot,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        if let fixtureRoot = fixtureRoot {
            try? fileManager.removeItem(at: fixtureRoot)
        }
        super.tearDown()
    }

    func testLoadDocsFromExistingDirectory() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        let indexContent = "# Index\nThis is the index."
        try indexContent.write(
            to: docsURL.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8
        )

        let architectureContent = "# Architecture\nSystem architecture docs."
        try architectureContent.write(
            to: docsURL.appendingPathComponent("architecture.md"),
            atomically: true,
            encoding: .utf8
        )

        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs.count, 2)
        XCTAssertEqual(docs[0].slug, "architecture")
        XCTAssertEqual(docs[1].slug, "index")
        XCTAssertEqual(docs[0].filename, "architecture.md")
        XCTAssertEqual(docs[1].filename, "index.md")
        XCTAssertTrue(docs[0].content.contains("System architecture"))
        XCTAssertTrue(docs[1].content.contains("This is the index"))
    }

    func testLoadDocsFromEmptyDirectory() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs.count, 0)
    }

    func testLoadDocsFromMissingDirectory() {
        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs.count, 0)
    }

    func testLoadDocsIsSortedAlphabetically() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        try "# Zebra".write(
            to: docsURL.appendingPathComponent("zebra.md"),
            atomically: true,
            encoding: .utf8
        )
        try "# Apple".write(
            to: docsURL.appendingPathComponent("apple.md"),
            atomically: true,
            encoding: .utf8
        )
        try "# Mango".write(
            to: docsURL.appendingPathComponent("mango.md"),
            atomically: true,
            encoding: .utf8
        )

        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs.count, 3)
        XCTAssertEqual(docs[0].slug, "apple")
        XCTAssertEqual(docs[1].slug, "mango")
        XCTAssertEqual(docs[2].slug, "zebra")
    }

    func testLoadDocContentWithExistingFile() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        let content = "# Test Document\n\nThis is test content."
        let filePath = docsURL.appendingPathComponent("test.md")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        let loadedContent = service.loadDocContent(path: filePath.path)

        XCTAssertEqual(loadedContent, content)
    }

    func testLoadDocContentWithMissingFile() {
        let filePath = docsURL.appendingPathComponent("missing.md")

        let loadedContent = service.loadDocContent(path: filePath.path)

        XCTAssertNil(loadedContent)
    }

    func testDisplayTitleFormatsSlugCorrectly() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        try "Content".write(
            to: docsURL.appendingPathComponent("api-reference.md"),
            atomically: true,
            encoding: .utf8
        )
        try "Content".write(
            to: docsURL.appendingPathComponent("getting-started.md"),
            atomically: true,
            encoding: .utf8
        )

        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs[0].displayTitle, "Api Reference")
        XCTAssertEqual(docs[1].displayTitle, "Getting Started")
    }

    func testLoadDocsIgnoresHiddenFiles() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        try "Visible".write(
            to: docsURL.appendingPathComponent("visible.md"),
            atomically: true,
            encoding: .utf8
        )
        try "Hidden".write(
            to: docsURL.appendingPathComponent(".hidden.md"),
            atomically: true,
            encoding: .utf8
        )

        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs[0].slug, "visible")
    }

    func testLoadDocsIgnoresNonMarkdownFiles() throws {
        try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)

        try "Markdown".write(
            to: docsURL.appendingPathComponent("doc.md"),
            atomically: true,
            encoding: .utf8
        )
        try "Text".write(
            to: docsURL.appendingPathComponent("file.txt"),
            atomically: true,
            encoding: .utf8
        )
        try "YAML".write(
            to: docsURL.appendingPathComponent("config.yaml"),
            atomically: true,
            encoding: .utf8
        )

        let docs = service.loadDocs(from: docsURL.path)

        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs[0].slug, "doc")
    }
}
