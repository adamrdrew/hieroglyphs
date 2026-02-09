import XCTest
@testable import Hieroglyphs
import Foundation

final class PharaohServiceTests: XCTestCase {
    var service: PharaohService!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        service = PharaohService()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        service.stop()
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testReadStatusReturnsNotRunningWhenFileDoesNotExist() {
        let status = service.readStatus(from: tempDirectory.path)
        XCTAssertEqual(status, .notRunning)
    }

    func testReadStatusReturnsIdleWhenStatusIsIdle() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "idle"}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        XCTAssertEqual(status, .idle)
    }

    func testReadStatusReturnsBusyWhenStatusIsBusy() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "busy", "phase": "test-phase"}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        if case .busy(let phase) = status {
            XCTAssertEqual(phase, "test-phase")
        } else {
            XCTFail("Expected busy status")
        }
    }

    func testReadStatusReturnsDoneWhenStatusIsDone() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "done", "phase": "test-phase", "cost": 1.5, "turns": 10}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        if case .done(let phase, let cost, let turns) = status {
            XCTAssertEqual(phase, "test-phase")
            XCTAssertEqual(cost, 1.5, accuracy: 0.01)
            XCTAssertEqual(turns, 10)
        } else {
            XCTFail("Expected done status")
        }
    }

    func testReadStatusReturnsBlockedWhenStatusIsBlocked() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "blocked", "phase": "test-phase", "error": "Test error"}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        if case .blocked(let phase, let error) = status {
            XCTAssertEqual(phase, "test-phase")
            XCTAssertEqual(error, "Test error")
        } else {
            XCTFail("Expected blocked status")
        }
    }

    func testReadLogsReturnsEmptyWhenFileDoesNotExist() {
        let logs = service.readLogs(from: tempDirectory.path, count: 10)
        XCTAssertTrue(logs.isEmpty)
    }

    func testReadLogsReturnsLastNLines() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let logFile = pharaohDir.appendingPathComponent("pharaoh.log")
        let logContent = """
        line 1
        line 2
        line 3
        line 4
        line 5
        """
        try logContent.write(to: logFile, atomically: true, encoding: .utf8)

        let logs = service.readLogs(from: tempDirectory.path, count: 3)
        XCTAssertEqual(logs.count, 3)
        XCTAssertEqual(logs[0], "line 3")
        XCTAssertEqual(logs[1], "line 4")
        XCTAssertEqual(logs[2], "line 5")
    }

    func testReadLogsReturnsAllLinesWhenCountExceedsTotal() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let logFile = pharaohDir.appendingPathComponent("pharaoh.log")
        let logContent = """
        line 1
        line 2
        line 3
        """
        try logContent.write(to: logFile, atomically: true, encoding: .utf8)

        let logs = service.readLogs(from: tempDirectory.path, count: 100)
        XCTAssertEqual(logs.count, 3)
        XCTAssertEqual(logs[0], "line 1")
        XCTAssertEqual(logs[1], "line 2")
        XCTAssertEqual(logs[2], "line 3")
    }
}
