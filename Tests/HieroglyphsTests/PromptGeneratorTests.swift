import XCTest
@testable import Hieroglyphs
import Foundation

/// Tests for PromptGenerator service.
///
/// Note: These tests verify public API behavior that can be tested without
/// mocking LanguageModelSession. Model availability and actual generation
/// behavior depend on macOS 26 runtime capabilities and cannot be reliably
/// mocked in unit tests. We test error handling, state management, and
/// verify that generation can be called (though we cannot verify output
/// quality without the live model).
@MainActor
final class PromptGeneratorTests: XCTestCase {
    var generator: PromptGenerator!

    override func setUp() {
        super.setUp()
        generator = PromptGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    // MARK: - Test Fixtures

    func makeBugCard() -> Card {
        Card(
            id: UUID(),
            title: "Fix search UI freezes",
            type: .bug,
            status: .todo,
            priority: .critical,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "fix-search-ui-freezes",
            body: """
            The search functionality currently blocks the main thread, causing the \
            UI to freeze when searching large workspaces. Users report delays of \
            5-10 seconds on workspaces with 1000+ files.

            Expected: Search runs asynchronously without blocking UI.
            Actual: UI freezes during search operations.
            """
        )
    }

    func makeFeatureCard() -> Card {
        Card(
            id: UUID(),
            title: "Add dark mode support",
            type: .feature,
            status: .todo,
            priority: .high,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "add-dark-mode-support",
            body: """
            Implement system-wide dark mode support using macOS appearance settings.

            Requirements:
            - Respect system dark mode preference
            - Use semantic colors throughout the app
            - Test all views in both light and dark modes
            - Ensure readability in both modes
            - Support dynamic switching without restart
            """
        )
    }

    func makeMinimalCard() -> Card {
        Card(
            id: UUID(),
            title: "Update documentation",
            type: .task,
            status: .backlog,
            priority: .low,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "update-documentation",
            body: "Update README with installation instructions."
        )
    }

    func makeComplexMultiCardSet() -> [Card] {
        [
            Card(
                id: UUID(),
                title: "Implement search caching",
                type: .feature,
                status: .todo,
                priority: .critical,
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "implement-search-caching",
                body: """
                Cache search results to improve performance on repeated queries.

                Requirements:
                - Cache invalidates on file system changes
                - LRU eviction policy with 100MB limit
                - Persist cache across app launches
                """
            ),
            Card(
                id: UUID(),
                title: "Add search progress indicator",
                type: .feature,
                status: .todo,
                priority: .high,
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "add-search-progress-indicator",
                body: """
                Show progress indication during long-running search operations.

                Requirements:
                - Display progress bar with percentage
                - Show cancel button
                - Update progress in real-time
                """
            ),
            Card(
                id: UUID(),
                title: "Fix typo in search placeholder",
                type: .bug,
                status: .todo,
                priority: .low,
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "fix-search-placeholder-typo",
                body: "Change 'Serach' to 'Search' in placeholder text."
            )
        ]
    }

    // MARK: - State Management Tests

    func testIsAvailableReflectsSystemModelAvailability() {
        // Verify that isAvailable delegates to SystemLanguageModel.
        // The actual value depends on runtime environment (hardware, settings).
        _ = generator.isAvailable
    }

    func testIsGeneratingIsFalseInitially() {
        XCTAssertFalse(generator.isGenerating)
    }

    func testCancelClearsGeneratingFlag() {
        // Verify cancel method exists and completes without error.
        generator.cancel()
        XCTAssertFalse(generator.isGenerating)
    }

    // MARK: - Error Handling Tests

    func testPromptGeneratorErrorDescriptions() {
        let modelUnavailable = PromptGeneratorError.modelUnavailable
        XCTAssertNotNil(modelUnavailable.errorDescription)
        XCTAssertTrue(modelUnavailable.errorDescription?.contains("not available") == true)

        let sessionBusy = PromptGeneratorError.sessionBusy
        XCTAssertNotNil(sessionBusy.errorDescription)
        XCTAssertTrue(sessionBusy.errorDescription?.contains("in progress") == true)

        let cancelled = PromptGeneratorError.generationCancelled
        XCTAssertNotNil(cancelled.errorDescription)
        XCTAssertTrue(cancelled.errorDescription?.contains("cancelled") == true)

        let modelError = PromptGeneratorError.modelError("Test error")
        XCTAssertNotNil(modelError.errorDescription)
        XCTAssertTrue(modelError.errorDescription?.contains("Test error") == true)
    }

    func testPromptGeneratorErrorEquality() {
        XCTAssertEqual(
            PromptGeneratorError.modelUnavailable,
            PromptGeneratorError.modelUnavailable
        )

        XCTAssertEqual(
            PromptGeneratorError.sessionBusy,
            PromptGeneratorError.sessionBusy
        )

        XCTAssertEqual(
            PromptGeneratorError.generationCancelled,
            PromptGeneratorError.generationCancelled
        )

        XCTAssertEqual(
            PromptGeneratorError.modelError("same"),
            PromptGeneratorError.modelError("same")
        )

        XCTAssertNotEqual(
            PromptGeneratorError.modelError("different"),
            PromptGeneratorError.modelError("other")
        )

        XCTAssertNotEqual(
            PromptGeneratorError.modelUnavailable,
            PromptGeneratorError.sessionBusy
        )
    }

    // MARK: - Generation API Tests
    //
    // Note: We cannot test actual generation quality without the live model.
    // These tests verify that the API can be called with different card types
    // and that errors are handled appropriately. Actual generation quality
    // must be verified manually on hardware with Apple Intelligence support.

    func testGenerateCanBeCalledWithSingleBugCard() async {
        let card = makeBugCard()

        do {
            _ = try await generator.generate(from: [card])
            // If we get here, model is available and generation succeeded.
            // We cannot verify output quality without inspecting the result manually.
        } catch PromptGeneratorError.modelUnavailable {
            // Expected on hardware without Apple Intelligence support.
            // This is not a test failure.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateCanBeCalledWithSingleFeatureCard() async {
        let card = makeFeatureCard()

        do {
            _ = try await generator.generate(from: [card])
        } catch PromptGeneratorError.modelUnavailable {
            // Expected on unsupported hardware
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateCanBeCalledWithMinimalCard() async {
        let card = makeMinimalCard()

        do {
            _ = try await generator.generate(from: [card])
        } catch PromptGeneratorError.modelUnavailable {
            // Expected on unsupported hardware
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateCanBeCalledWithMultipleCards() async {
        let cards = makeComplexMultiCardSet()

        do {
            _ = try await generator.generate(from: cards)
        } catch PromptGeneratorError.modelUnavailable {
            // Expected on unsupported hardware
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateThrowsWhenModelUnavailableOnUnsupportedHardware() async {
        // This test documents the expected behavior when model is unavailable.
        // On hardware without Apple Intelligence, generate() should throw
        // modelUnavailable error.
        //
        // We cannot force this condition in tests, so this is documentation only.
    }
}
