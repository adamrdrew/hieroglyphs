import XCTest
@testable import Hieroglyphs

final class TagReconcilerServiceTests: XCTestCase {
    var tempDirectory: URL!
    var tempFilePath: String!
    var service: TagReconcilerService!

    override func setUp() {
        super.setUp()
        service = TagReconcilerService()

        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )

        let tempFile = tempDirectory.appendingPathComponent("test.md")
        try? "Test content".write(to: tempFile, atomically: true, encoding: .utf8)
        tempFilePath = tempFile.path
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        super.tearDown()
    }

    func testReconcileNonEmptyTagsWritesPlist() throws {
        let tags = ["work", "urgent"]
        service.reconcileTags(for: tags, at: tempFilePath)

        let attributes = try readExtendedAttribute(at: tempFilePath)
        XCTAssertTrue(attributes.contains("work"))
        XCTAssertTrue(attributes.contains("urgent"))
    }

    func testReconcileEmptyTagsRemovesAttribute() throws {
        service.reconcileTags(for: ["initial"], at: tempFilePath)

        let attributesBefore = try? readExtendedAttribute(at: tempFilePath)
        XCTAssertNotNil(attributesBefore)

        service.reconcileTags(for: [], at: tempFilePath)

        var attributesAfter: String?
        XCTAssertThrowsError(try {
            attributesAfter = try readExtendedAttribute(at: tempFilePath)
        }())
        XCTAssertNil(attributesAfter)
    }

    func testGeneratedPlistIsValidXML() throws {
        let tags = ["test", "sample"]
        service.reconcileTags(for: tags, at: tempFilePath)

        let plistData = try readExtendedAttributeData(at: tempFilePath)
        let parsed = try PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        )

        XCTAssertNotNil(parsed as? [String])
        let tagArray = parsed as? [String]
        XCTAssertEqual(tagArray?.count, 2)
        XCTAssertTrue(tagArray?.contains("test") ?? false)
        XCTAssertTrue(tagArray?.contains("sample") ?? false)
    }

    func testXMLSpecialCharactersEscaped() throws {
        let tags = ["<tag>", "foo&bar", "quote\"test"]
        service.reconcileTags(for: tags, at: tempFilePath)

        let plistData = try readExtendedAttributeData(at: tempFilePath)
        let parsed = try PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        )

        let tagArray = parsed as? [String]
        XCTAssertEqual(tagArray?.count, 3)
        XCTAssertTrue(tagArray?.contains("<tag>") ?? false)
        XCTAssertTrue(tagArray?.contains("foo&bar") ?? false)
        XCTAssertTrue(tagArray?.contains("quote\"test") ?? false)
    }

    private func readExtendedAttribute(at path: String) throws -> String {
        let data = try readExtendedAttributeData(at: path)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "Test",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode attribute"]
            )
        }
        return string
    }

    private func readExtendedAttributeData(at path: String) throws -> Data {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        task.arguments = ["-p", "com.apple.metadata:_kMDItemUserTags", path]

        let pipe = Pipe()
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw NSError(
                domain: "Test",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "xattr read failed"]
            )
        }

        return pipe.fileHandleForReading.readDataToEndOfFile()
    }
}
