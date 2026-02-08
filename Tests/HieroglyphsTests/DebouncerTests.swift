import XCTest
@testable import Hieroglyphs

@MainActor
final class DebouncerTests: XCTestCase {

    func testScheduledActionExecutesAfterDelay() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var executed = false

        debouncer.schedule {
            executed = true
        }

        XCTAssertFalse(executed, "Action should not execute immediately")

        try await Task.sleep(for: .seconds(0.15))

        XCTAssertTrue(executed, "Action should execute after delay")
    }

    func testMultipleSchedulesCoalesceToSingleExecution() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var executionCount = 0

        debouncer.schedule {
            executionCount += 1
        }

        debouncer.schedule {
            executionCount += 1
        }

        debouncer.schedule {
            executionCount += 1
        }

        try await Task.sleep(for: .seconds(0.15))

        XCTAssertEqual(
            executionCount,
            1,
            "Only the last scheduled action should execute"
        )
    }

    func testFlushExecutesActionImmediately() async throws {
        let debouncer = Debouncer(delay: 0.5)
        var executed = false

        debouncer.schedule {
            executed = true
        }

        XCTAssertFalse(executed, "Action should not execute before flush")

        debouncer.flush()

        XCTAssertTrue(executed, "Action should execute immediately on flush")

        try await Task.sleep(for: .seconds(0.6))

        XCTAssertEqual(
            executed,
            true,
            "Action should not execute again after flush"
        )
    }

    func testCancelPreventsExecution() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var executed = false

        debouncer.schedule {
            executed = true
        }

        debouncer.cancel()

        try await Task.sleep(for: .seconds(0.15))

        XCTAssertFalse(executed, "Action should not execute after cancel")
    }

    func testFlushWithNoPendingActionDoesNothing() {
        let debouncer = Debouncer(delay: 0.1)

        debouncer.flush()

        // No assertion needed - test passes if no crash or error occurs
    }

    func testCancelWithNoPendingActionDoesNothing() {
        let debouncer = Debouncer(delay: 0.1)

        debouncer.cancel()

        // No assertion needed - test passes if no crash or error occurs
    }

    func testRapidScheduleAndFlush() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var value = 0

        debouncer.schedule {
            value = 1
        }

        debouncer.schedule {
            value = 2
        }

        debouncer.schedule {
            value = 3
        }

        debouncer.flush()

        XCTAssertEqual(value, 3, "Flush should execute most recent action")

        try await Task.sleep(for: .seconds(0.15))

        XCTAssertEqual(
            value,
            3,
            "Value should not change after flush"
        )
    }
}
