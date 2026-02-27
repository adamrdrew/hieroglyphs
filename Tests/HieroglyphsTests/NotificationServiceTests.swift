import XCTest
@testable import Hieroglyphs

/// Records calls to NotificationDispatching methods for test verification.
@MainActor
final class MockNotificationService: NotificationDispatching {
    var setUpCallCount = 0

    struct CompletedCall: Equatable {
        let projectName: String
        let phaseName: String
        let turns: Int
        let costUsd: Double
    }

    struct FailedCall: Equatable {
        let projectName: String
        let phaseName: String
        let error: String
        let turns: Int
        let costUsd: Double
    }

    var completedCalls: [CompletedCall] = []
    var failedCalls: [FailedCall] = []

    func setUp() {
        setUpCallCount += 1
    }

    nonisolated func notifyPhaseCompleted(
        projectName: String,
        phaseName: String,
        turns: Int,
        costUsd: Double
    ) {
        MainActor.assumeIsolated {
            completedCalls.append(CompletedCall(
                projectName: projectName,
                phaseName: phaseName,
                turns: turns,
                costUsd: costUsd
            ))
        }
    }

    nonisolated func notifyPhaseFailed(
        projectName: String,
        phaseName: String,
        error: String,
        turns: Int,
        costUsd: Double
    ) {
        MainActor.assumeIsolated {
            failedCalls.append(FailedCall(
                projectName: projectName,
                phaseName: phaseName,
                error: error,
                turns: turns,
                costUsd: costUsd
            ))
        }
    }
}

@MainActor
final class NotificationServiceTests: XCTestCase {
    var mock: MockNotificationService!

    override func setUp() {
        super.setUp()
        mock = MockNotificationService()
    }

    // MARK: - Protocol method recording tests

    func testSetUpRecordsCall() {
        mock.setUp()
        XCTAssertEqual(mock.setUpCallCount, 1)
    }

    func testNotifyPhaseCompletedRecordsArguments() {
        mock.notifyPhaseCompleted(
            projectName: "Alpha",
            phaseName: "0001-init",
            turns: 5,
            costUsd: 0.1234
        )

        XCTAssertEqual(mock.completedCalls.count, 1)
        let call = mock.completedCalls[0]
        XCTAssertEqual(call.projectName, "Alpha")
        XCTAssertEqual(call.phaseName, "0001-init")
        XCTAssertEqual(call.turns, 5)
        XCTAssertEqual(call.costUsd, 0.1234, accuracy: 0.0001)
    }

    func testNotifyPhaseFailedRecordsArguments() {
        mock.notifyPhaseFailed(
            projectName: "Beta",
            phaseName: "0002-fix",
            error: "Build failed",
            turns: 3,
            costUsd: 0.0567
        )

        XCTAssertEqual(mock.failedCalls.count, 1)
        let call = mock.failedCalls[0]
        XCTAssertEqual(call.projectName, "Beta")
        XCTAssertEqual(call.phaseName, "0002-fix")
        XCTAssertEqual(call.error, "Build failed")
        XCTAssertEqual(call.turns, 3)
        XCTAssertEqual(call.costUsd, 0.0567, accuracy: 0.0001)
    }

    // MARK: - Transition detection tests

    func testBusyToDoneFiresCompleted() {
        let previous: PharaohStatus = .busy(
            phase: "0010-build",
            turnsElapsed: 8,
            runningCostUsd: 0.25,
            phaseStarted: nil
        )
        let current: PharaohStatus = .done(
            phase: "0010-build",
            costUsd: 0.30,
            turns: 10
        )

        detectPharaohTransition(
            from: previous,
            to: current,
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 1)
        XCTAssertEqual(mock.failedCalls.count, 0)
        let call = mock.completedCalls[0]
        XCTAssertEqual(call.projectName, "TestProject")
        XCTAssertEqual(call.phaseName, "0010-build")
        XCTAssertEqual(call.turns, 10)
        XCTAssertEqual(call.costUsd, 0.30, accuracy: 0.001)
    }

    func testBusyToBlockedFiresFailed() {
        let previous: PharaohStatus = .busy(
            phase: "0020-review",
            turnsElapsed: 4,
            runningCostUsd: 0.10,
            phaseStarted: nil
        )
        let current: PharaohStatus = .blocked(
            phase: "0020-review",
            error: "Compilation error",
            costUsd: 0.12,
            turns: 5
        )

        detectPharaohTransition(
            from: previous,
            to: current,
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.failedCalls.count, 1)
        XCTAssertEqual(mock.completedCalls.count, 0)
        let call = mock.failedCalls[0]
        XCTAssertEqual(call.projectName, "TestProject")
        XCTAssertEqual(call.phaseName, "0020-review")
        XCTAssertEqual(call.error, "Compilation error")
        XCTAssertEqual(call.turns, 5)
        XCTAssertEqual(call.costUsd, 0.12, accuracy: 0.001)
    }

    func testBusyToIdleFiresNothing() {
        let previous: PharaohStatus = .busy(
            phase: "0030-fix",
            turnsElapsed: 2,
            runningCostUsd: 0.05,
            phaseStarted: nil
        )

        detectPharaohTransition(
            from: previous,
            to: .idle,
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 0)
        XCTAssertEqual(mock.failedCalls.count, 0)
    }

    func testIdleToBusyFiresNothing() {
        detectPharaohTransition(
            from: .idle,
            to: .busy(
                phase: "0040-plan",
                turnsElapsed: 1,
                runningCostUsd: 0.01,
                phaseStarted: nil
            ),
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 0)
        XCTAssertEqual(mock.failedCalls.count, 0)
    }

    func testNilToBusyFiresNothing() {
        detectPharaohTransition(
            from: nil,
            to: .busy(
                phase: "0050-init",
                turnsElapsed: 0,
                runningCostUsd: 0.0,
                phaseStarted: nil
            ),
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 0)
        XCTAssertEqual(mock.failedCalls.count, 0)
    }

    func testBusyToBusyFiresNothing() {
        let previous: PharaohStatus = .busy(
            phase: "0060-build",
            turnsElapsed: 3,
            runningCostUsd: 0.08,
            phaseStarted: nil
        )
        let current: PharaohStatus = .busy(
            phase: "0060-build",
            turnsElapsed: 4,
            runningCostUsd: 0.10,
            phaseStarted: nil
        )

        detectPharaohTransition(
            from: previous,
            to: current,
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 0)
        XCTAssertEqual(mock.failedCalls.count, 0)
    }

    func testBusyToNotRunningFiresNothing() {
        let previous: PharaohStatus = .busy(
            phase: "0070-test",
            turnsElapsed: 2,
            runningCostUsd: 0.04,
            phaseStarted: nil
        )

        detectPharaohTransition(
            from: previous,
            to: .notRunning,
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 0)
        XCTAssertEqual(mock.failedCalls.count, 0)
    }

    func testDoneToBusyFiresNothing() {
        let previous: PharaohStatus = .done(
            phase: "0080-done",
            costUsd: 0.50,
            turns: 12
        )

        detectPharaohTransition(
            from: previous,
            to: .busy(
                phase: "0081-next",
                turnsElapsed: 0,
                runningCostUsd: 0.0,
                phaseStarted: nil
            ),
            projectName: "TestProject",
            notifier: mock
        )

        XCTAssertEqual(mock.completedCalls.count, 0)
        XCTAssertEqual(mock.failedCalls.count, 0)
    }
}
