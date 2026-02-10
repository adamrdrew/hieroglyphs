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
        {"status": "busy", "phase": "test-phase", "turnsElapsed": 5, "runningCostUsd": 0.123, "phaseStarted": "2024-01-01T12:00:00.000Z"}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        if case .busy(let phase, let turnsElapsed, let runningCostUsd, let phaseStarted) = status {
            XCTAssertEqual(phase, "test-phase")
            XCTAssertEqual(turnsElapsed, 5)
            XCTAssertEqual(runningCostUsd, 0.123, accuracy: 0.001)
            XCTAssertNotNil(phaseStarted)
        } else {
            XCTFail("Expected busy status")
        }
    }

    func testReadStatusReturnsDoneWhenStatusIsDone() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "done", "phase": "test-phase", "costUsd": 1.5, "turns": 10}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        if case .done(let phase, let costUsd, let turns) = status {
            XCTAssertEqual(phase, "test-phase")
            XCTAssertEqual(costUsd, 1.5, accuracy: 0.01)
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
        {"status": "blocked", "phase": "test-phase", "error": "Test error", "costUsd": 2.5, "turns": 7}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let status = service.readStatus(from: tempDirectory.path)
        if case .blocked(let phase, let error, let costUsd, let turns) = status {
            XCTAssertEqual(phase, "test-phase")
            XCTAssertEqual(error, "Test error")
            XCTAssertEqual(costUsd, 2.5, accuracy: 0.01)
            XCTAssertEqual(turns, 7)
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

    func testReadEventsReturnsEmptyWhenFileDoesNotExist() {
        let events = service.readEvents(from: tempDirectory.path)
        XCTAssertTrue(events.isEmpty)
    }

    func testReadEventsReturnsEmptyWhenFileIsEmpty() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        try "".write(to: eventsFile, atomically: true, encoding: .utf8)

        let events = service.readEvents(from: tempDirectory.path)
        XCTAssertTrue(events.isEmpty)
    }

    func testReadEventsParsesMalformedLinesGracefully() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        let content = """
        {"timestamp": "2024-01-01T12:00:00.000Z", "type": "tool_call", "summary": "Valid event"}
        invalid json line
        {"timestamp": "2024-01-01T12:01:00.000Z", "type": "result", "summary": "Another valid event"}
        """
        try content.write(to: eventsFile, atomically: true, encoding: .utf8)

        let events = service.readEvents(from: tempDirectory.path)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].type, .toolCall)
        XCTAssertEqual(events[0].summary, "Valid event")
        XCTAssertEqual(events[1].type, .result)
        XCTAssertEqual(events[1].summary, "Another valid event")
    }

    func testReadEventsIncludesDetailJson() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        let content = """
        {"timestamp": "2024-01-01T12:00:00.000Z", "type": "tool_call", "summary": "Test", "detail": {"key": "value"}}
        """
        try content.write(to: eventsFile, atomically: true, encoding: .utf8)

        let events = service.readEvents(from: tempDirectory.path)
        XCTAssertEqual(events.count, 1)
        XCTAssertNotNil(events[0].detailJson)
        XCTAssertTrue(events[0].detailJson!.contains("key"))
    }

    func testReadEventsReturnsAllEventTypes() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        let content = """
        {"timestamp": "2024-01-01T12:00:00.000Z", "type": "tool_call", "summary": "Tool call"}
        {"timestamp": "2024-01-01T12:01:00.000Z", "type": "tool_progress", "summary": "Progress"}
        {"timestamp": "2024-01-01T12:02:00.000Z", "type": "tool_summary", "summary": "Summary"}
        {"timestamp": "2024-01-01T12:03:00.000Z", "type": "text", "summary": "Text"}
        {"timestamp": "2024-01-01T12:04:00.000Z", "type": "turn", "summary": "Turn 1"}
        {"timestamp": "2024-01-01T12:05:00.000Z", "type": "status", "summary": "Status"}
        {"timestamp": "2024-01-01T12:06:00.000Z", "type": "result", "summary": "Result"}
        {"timestamp": "2024-01-01T12:07:00.000Z", "type": "error", "summary": "Error"}
        """
        try content.write(to: eventsFile, atomically: true, encoding: .utf8)

        let events = service.readEvents(from: tempDirectory.path)
        XCTAssertEqual(events.count, 8)
        XCTAssertEqual(events[0].type, .toolCall)
        XCTAssertEqual(events[1].type, .toolProgress)
        XCTAssertEqual(events[2].type, .toolSummary)
        XCTAssertEqual(events[3].type, .text)
        XCTAssertEqual(events[4].type, .turn)
        XCTAssertEqual(events[5].type, .status)
        XCTAssertEqual(events[6].type, .result)
        XCTAssertEqual(events[7].type, .error)
    }
}
