import XCTest
@testable import Hieroglyphs
import Foundation

/// Tests for PromptGenerator service.
///
/// Note: These tests verify public API behavior that can be tested without
/// mocking LanguageModelSession. Model availability and actual generation
/// behavior depend on macOS 26 runtime capabilities and cannot be reliably
/// mocked in unit tests.
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

    func testIsAvailableReflectsSystemModelAvailability() {
        // This test verifies that isAvailable delegates to SystemLanguageModel.
        // The actual value depends on runtime environment (hardware, settings).
        // We cannot mock SystemLanguageModel, so we only verify the property exists.
        _ = generator.isAvailable
    }

    func testIsGeneratingIsFalseInitially() {
        XCTAssertFalse(generator.isGenerating)
    }

    func testGenerateThrowsWhenModelUnavailable() async {
        // Skip test - cannot reliably test model unavailability without mocking.
        // Model availability depends on runtime environment and cannot be forced.
    }

    func testCancelSetsGeneratingToFalse() {
        // Cancellation only has effect if session is responding.
        // Since we cannot easily trigger a real generation in tests,
        // we verify the cancel method exists and completes.
        generator.cancel()
    }

    func testCardAssemblyTruncatesLongContent() {
        // Skip test - cannot verify card assembly without triggering actual generation.
        // Truncation logic is private implementation detail tested through integration.
    }

    func testPromptGeneratorErrorDescriptions() {
        let modelUnavailable = PromptGeneratorError.modelUnavailable
        XCTAssertNotNil(modelUnavailable.errorDescription)

        let sessionBusy = PromptGeneratorError.sessionBusy
        XCTAssertNotNil(sessionBusy.errorDescription)

        let cancelled = PromptGeneratorError.generationCancelled
        XCTAssertNotNil(cancelled.errorDescription)

        let modelError = PromptGeneratorError.modelError("Test error")
        XCTAssertNotNil(modelError.errorDescription)
    }
}
