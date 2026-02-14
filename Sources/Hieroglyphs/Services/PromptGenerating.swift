import Foundation

/// Protocol defining the contract for on-device phase prompt generation.
///
/// PromptGenerating services use Apple's FoundationModels framework to generate
/// Scribe phase prompts from linked cards. Generation respects the 4096 token
/// context window limit via truncation strategy: prioritize card titles and
/// requirements, truncate body content if total length exceeds limit.
@MainActor
protocol PromptGenerating {
    /// True when the on-device language model is available for use.
    ///
    /// Availability depends on macOS 26 hardware capabilities and user settings.
    /// Check this before presenting generation UI to avoid offering unavailable features.
    var isAvailable: Bool { get }

    /// True during active prompt generation.
    ///
    /// Use this to disable UI controls and show progress indication while generation
    /// is in progress.
    var isGenerating: Bool { get }

    /// Generate a Scribe phase prompt from the provided cards.
    ///
    /// - Parameter cards: Array of cards to summarize into a phase prompt.
    /// - Returns: Generated phase prompt text (markdown format).
    /// - Throws: `PromptGeneratorError` on model errors or cancellation.
    ///
    /// The method assembles card titles, types, priorities, and body content into
    /// a concise summary, respecting the 4096 token limit via character count
    /// approximation (1 token ≈ 4 characters). Body content is truncated if needed
    /// to fit within the context window.
    func generate(from cards: [Card]) async throws -> String

    /// Request cancellation of in-progress generation.
    ///
    /// Note: LanguageModelSession does not support true cancellation. This method
    /// sets a flag that is checked after response completes. If the flag is set,
    /// the result is discarded and an error is thrown.
    func cancel()
}
