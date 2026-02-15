import XCTest
@testable import Hieroglyphs

final class CommandExecutionServiceTests: XCTestCase {

    private var service: CommandExecutionService!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        service = CommandExecutionService(timeout: 5.0)
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    // MARK: - Success Tests

    func testExecuteCommandSuccess() async throws {
        let result = try await service.executeCommand(
            command: "echo 'test output'",
            workingDirectory: tempDir.path
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("test output"))
    }

    func testExecuteCommandCapturesOutput() async throws {
        let result = try await service.executeCommand(
            command: "echo 'hello world'",
            workingDirectory: tempDir.path
        )

        XCTAssertTrue(result.output.contains("hello world"))
        XCTAssertEqual(result.exitCode, 0)
    }

    func testExecuteCommandWithWorkingDirectory() async throws {
        let testFilePath = tempDir.appendingPathComponent("testfile.txt")
        try "test content".write(to: testFilePath, atomically: true, encoding: .utf8)

        let result = try await service.executeCommand(
            command: "ls testfile.txt",
            workingDirectory: tempDir.path
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("testfile.txt"))
    }

    // MARK: - Failure Tests

    func testExecuteCommandNonZeroExit() async throws {
        do {
            _ = try await service.executeCommand(
                command: "exit 1",
                workingDirectory: tempDir.path
            )
            XCTFail("Expected command to throw on non-zero exit")
        } catch let error as CommandExecutionService.CommandError {
            if case .nonZeroExit(let code, _) = error {
                XCTAssertEqual(code, 1)
            } else {
                XCTFail("Expected nonZeroExit error")
            }
        }
    }

    func testExecuteCommandCapturesStderr() async throws {
        do {
            _ = try await service.executeCommand(
                command: "echo 'error message' >&2 && exit 1",
                workingDirectory: tempDir.path
            )
            XCTFail("Expected command to throw")
        } catch let error as CommandExecutionService.CommandError {
            if case .nonZeroExit(_, let errorOutput) = error {
                XCTAssertTrue(errorOutput.contains("error message"))
            } else {
                XCTFail("Expected nonZeroExit error")
            }
        }
    }

    // MARK: - Edge Cases

    func testExecuteCommandEmptyOutput() async throws {
        let result = try await service.executeCommand(
            command: "true",
            workingDirectory: tempDir.path
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.isEmpty || result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testExecuteCommandMultilineOutput() async throws {
        let result = try await service.executeCommand(
            command: "echo 'line 1'; echo 'line 2'; echo 'line 3'",
            workingDirectory: tempDir.path
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("line 1"))
        XCTAssertTrue(result.output.contains("line 2"))
        XCTAssertTrue(result.output.contains("line 3"))
    }
}
