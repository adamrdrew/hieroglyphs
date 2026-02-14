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

    func testStartThrowsErrorWhenDirectoryDoesNotExist() {
        let nonexistentPath = "/nonexistent/path/\(UUID().uuidString)"
        XCTAssertThrowsError(try service.start(in: nonexistentPath, model: "opus")) { error in
            guard case PharaohError.directoryNotFound(let path) = error else {
                XCTFail("Expected directoryNotFound error")
                return
            }
            XCTAssertEqual(path, nonexistentPath)
        }
    }

    func testStartAcceptsModelParameter() throws {
        XCTAssertNoThrow(try service.start(in: tempDirectory.path, model: "opus"))
        service.stop()
        XCTAssertNoThrow(try service.start(in: tempDirectory.path, model: "sonnet"))
        service.stop()
        XCTAssertNoThrow(try service.start(in: tempDirectory.path, model: "haiku"))
    }

    func testReadServerInfoReturnsValidDataWhenFileIsValid() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let serverInfoFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {
            "status": "idle",
            "pid": 12345,
            "started": "2024-01-01T12:00:00.000Z",
            "pharaohVersion": "1.0.0",
            "ushabtiVersion": "2.0.0",
            "model": "opus",
            "cwd": "/test/directory",
            "phasesCompleted": 5
        }
        """
        try json.write(to: serverInfoFile, atomically: true, encoding: .utf8)

        let serverInfo = service.readServerInfo(from: tempDirectory.path)
        XCTAssertNotNil(serverInfo)
        XCTAssertEqual(serverInfo?.status, "idle")
        XCTAssertEqual(serverInfo?.pid, 12345)
        XCTAssertEqual(serverInfo?.pharaohVersion, "1.0.0")
        XCTAssertEqual(serverInfo?.ushabtiVersion, "2.0.0")
        XCTAssertEqual(serverInfo?.model, "opus")
        XCTAssertEqual(serverInfo?.cwd, "/test/directory")
        XCTAssertEqual(serverInfo?.phasesCompleted, 5)
        XCTAssertNotNil(serverInfo?.started)
    }

    func testReadServerInfoReturnsNilWhenFileDoesNotExist() {
        let serverInfo = service.readServerInfo(from: tempDirectory.path)
        XCTAssertNil(serverInfo)
    }

    func testReadServerInfoReturnsNilWhenJSONIsMalformed() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let serverInfoFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let malformedJson = "not valid json"
        try malformedJson.write(to: serverInfoFile, atomically: true, encoding: .utf8)

        let serverInfo = service.readServerInfo(from: tempDirectory.path)
        XCTAssertNil(serverInfo)
    }

    func testReadServerInfoReturnsNilWhenRequiredFieldsAreMissing() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let serverInfoFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let incompleteJson = """
        {
            "status": "idle",
            "pid": 12345
        }
        """
        try incompleteJson.write(to: serverInfoFile, atomically: true, encoding: .utf8)

        let serverInfo = service.readServerInfo(from: tempDirectory.path)
        XCTAssertNil(serverInfo)
    }

    func testEventDetailParsingToolCall() {
        let detailJson = """
        {"tool_name": "Bash", "input": "ls -la"}
        """
        let event = PharaohEvent(
            id: 0,
            timestamp: Date(),
            type: .toolCall,
            summary: "Test",
            detailJson: detailJson
        )

        XCTAssertEqual(event.toolName, "Bash")
        XCTAssertEqual(event.toolInput, "ls -la")
    }

    func testEventDetailParsingTurn() {
        let detailJson = """
        {"turn": 3, "input_tokens": 1000, "output_tokens": 500}
        """
        let event = PharaohEvent(
            id: 0,
            timestamp: Date(),
            type: .turn,
            summary: "Test",
            detailJson: detailJson
        )

        XCTAssertEqual(event.turnNumber, 3)
        XCTAssertEqual(event.inputTokens, 1000)
        XCTAssertEqual(event.outputTokens, 500)
    }

    func testEventDetailParsingText() {
        let detailJson = """
        {"full_text": "This is the complete text content"}
        """
        let event = PharaohEvent(
            id: 0,
            timestamp: Date(),
            type: .text,
            summary: "Test",
            detailJson: detailJson
        )

        XCTAssertEqual(event.fullText, "This is the complete text content")
    }

    func testEventDetailParsingResult() {
        let detailJson = """
        {"turns": 10, "cost_usd": 1.5}
        """
        let event = PharaohEvent(
            id: 0,
            timestamp: Date(),
            type: .result,
            summary: "Test",
            detailJson: detailJson
        )

        XCTAssertEqual(event.resultTurns, 10)
        XCTAssertNotNil(event.resultCostUsd)
        if let cost = event.resultCostUsd {
            XCTAssertEqual(cost, 1.5, accuracy: 0.001)
        }
    }

    func testEventDetailParsingMalformedJson() {
        let event = PharaohEvent(
            id: 0,
            timestamp: Date(),
            type: .toolCall,
            summary: "Test",
            detailJson: "not valid json"
        )

        XCTAssertNil(event.toolName)
        XCTAssertNil(event.toolInput)
        XCTAssertNil(event.turnNumber)
        XCTAssertNil(event.inputTokens)
        XCTAssertNil(event.outputTokens)
        XCTAssertNil(event.fullText)
        XCTAssertNil(event.resultTurns)
        XCTAssertNil(event.resultCostUsd)
    }

    func testEventHasDetail() {
        let eventWithDetail = PharaohEvent(
            id: 0,
            timestamp: Date(),
            type: .toolCall,
            summary: "Test",
            detailJson: "{}"
        )
        XCTAssertTrue(eventWithDetail.hasDetail)

        let eventWithoutDetail = PharaohEvent(
            id: 1,
            timestamp: Date(),
            type: .toolCall,
            summary: "Test",
            detailJson: nil
        )
        XCTAssertFalse(eventWithoutDetail.hasDetail)
    }

    func testReadEventsReturnsStableIDs() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        let content = """
        {"timestamp": "2024-01-01T12:00:00.000Z", "type": "tool_call", "summary": "First event"}
        {"timestamp": "2024-01-01T12:01:00.000Z", "type": "result", "summary": "Second event"}
        """
        try content.write(to: eventsFile, atomically: true, encoding: .utf8)

        let firstRead = service.readEvents(from: tempDirectory.path)
        let secondRead = service.readEvents(from: tempDirectory.path)

        XCTAssertEqual(firstRead.count, 2)
        XCTAssertEqual(secondRead.count, 2)
        XCTAssertEqual(firstRead[0].id, secondRead[0].id)
        XCTAssertEqual(firstRead[1].id, secondRead[1].id)
    }

    func testReadEventsIndexBasedIDs() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        let content = """
        {"timestamp": "2024-01-01T12:00:00.000Z", "type": "tool_call", "summary": "Event 0"}
        {"timestamp": "2024-01-01T12:01:00.000Z", "type": "text", "summary": "Event 1"}
        {"timestamp": "2024-01-01T12:02:00.000Z", "type": "result", "summary": "Event 2"}
        """
        try content.write(to: eventsFile, atomically: true, encoding: .utf8)

        let events = service.readEvents(from: tempDirectory.path)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0].id, 0)
        XCTAssertEqual(events[1].id, 1)
        XCTAssertEqual(events[2].id, 2)
        XCTAssertEqual(events[0].summary, "Event 0")
        XCTAssertEqual(events[1].summary, "Event 1")
        XCTAssertEqual(events[2].summary, "Event 2")
    }

    func testReadStatusReturnsEqualValuesForUnchangedFile() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "idle"}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let firstStatus = service.readStatus(from: tempDirectory.path)
        let secondStatus = service.readStatus(from: tempDirectory.path)

        XCTAssertEqual(firstStatus, secondStatus)
        XCTAssertEqual(firstStatus, .idle)
    }

    func testReadEventsReturnsEqualArraysForUnchangedFile() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let eventsFile = pharaohDir.appendingPathComponent("events.jsonl")
        let content = """
        {"timestamp": "2024-01-01T12:00:00.000Z", "type": "tool_call", "summary": "Event 1"}
        {"timestamp": "2024-01-01T12:01:00.000Z", "type": "result", "summary": "Event 2"}
        """
        try content.write(to: eventsFile, atomically: true, encoding: .utf8)

        let firstRead = service.readEvents(from: tempDirectory.path)
        let secondRead = service.readEvents(from: tempDirectory.path)

        XCTAssertEqual(firstRead.count, secondRead.count)
        XCTAssertEqual(firstRead[0].id, secondRead[0].id)
        XCTAssertEqual(firstRead[0].summary, secondRead[0].summary)
        XCTAssertEqual(firstRead[1].id, secondRead[1].id)
        XCTAssertEqual(firstRead[1].summary, secondRead[1].summary)
    }

    func testCleanupStaleProcessReturnsNoStaleProcessWhenFileDoesNotExist() {
        let result = service.cleanupStaleProcess(in: tempDirectory.path)
        XCTAssertEqual(result, .noStaleProcess)
    }

    func testCleanupStaleProcessReturnsNoStaleProcessWhenPidFieldMissing() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "idle"}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let result = service.cleanupStaleProcess(in: tempDirectory.path)
        XCTAssertEqual(result, .noStaleProcess)
    }

    func testCleanupStaleProcessReturnsStaleFileOnlyWhenProcessNotRunning() throws {
        let pharaohDir = tempDirectory.appendingPathComponent(".pharaoh")
        try FileManager.default.createDirectory(at: pharaohDir, withIntermediateDirectories: true)

        let statusFile = pharaohDir.appendingPathComponent("pharaoh.json")
        let json = """
        {"status": "idle", "pid": 999999}
        """
        try json.write(to: statusFile, atomically: true, encoding: .utf8)

        let result = service.cleanupStaleProcess(in: tempDirectory.path)
        XCTAssertEqual(result, .staleFileOnly)
    }

    func testStartRefusesDoubleStart() throws {
        try service.start(in: tempDirectory.path, model: "opus")

        XCTAssertThrowsError(try service.start(in: tempDirectory.path, model: "opus")) { error in
            guard case PharaohError.processAlreadyRunning = error else {
                XCTFail("Expected processAlreadyRunning error")
                return
            }
        }
    }
}
