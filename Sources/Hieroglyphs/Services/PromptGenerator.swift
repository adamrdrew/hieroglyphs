import Foundation
import FoundationModels
import SwiftUI
import os

/// Structured schema for phase prompt generation.
///
/// Constrains model output to specific fields, reducing hallucination by
/// requiring explicit field population rather than free-form narrative.
@Generable
struct PhasePromptSchema {
    @Guide("2-3 sentences using only information from the provided cards. Reference card titles.")
    var context: String

    @Guide("Features, fixes, or changes from card bodies only. No invented UI flows or application behavior.")
    var whatToBuild: String

    @Guide("Constraints, acceptance criteria, and success conditions from cards only.")
    var requirements: String

    @Guide("List of card titles being addressed. Use exact titles from input.")
    var cardsAddressed: [String]
}

/// Errors thrown by PromptGenerator during generation.
enum PromptGeneratorError: Error, LocalizedError, Equatable {
    case modelUnavailable
    case sessionBusy
    case generationCancelled
    case modelError(String)

    static func == (lhs: PromptGeneratorError, rhs: PromptGeneratorError) -> Bool {
        switch (lhs, rhs) {
        case (.modelUnavailable, .modelUnavailable):
            return true
        case (.sessionBusy, .sessionBusy):
            return true
        case (.generationCancelled, .generationCancelled):
            return true
        case (.modelError(let lhsMsg), .modelError(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "On-device language model is not available."
        case .sessionBusy:
            return "A generation is already in progress. Please try again."
        case .generationCancelled:
            return "Generation was cancelled."
        case .modelError(let errorMessage):
            return "Generation failed: \(errorMessage)"
        }
    }
}

/// On-device phase prompt generator using Apple's FoundationModels framework.
///
/// PromptGenerator assembles card data into a concise summary and uses the system
/// language model to generate structured Scribe phase prompts. Generation respects
/// the 4096 token context window via simple character count heuristic (1 token ≈ 4 chars).
@MainActor
final class PromptGenerator: PromptGenerating {
    private let languageModel = SystemLanguageModel.default
    private let logger = Logger(
        subsystem: "com.adamdrew.hieroglyphs",
        category: "PromptGenerator"
    )

    @Published private(set) var isGenerating = false
    private var sessionCancelled = false
    private var session: LanguageModelSession

    var isAvailable: Bool {
        languageModel.isAvailable
    }

    init() {
        self.session = LanguageModelSession(instructions: ScribePromptInstructions.text)
    }

    func generate(from cards: [Card]) async throws -> String {
        guard isAvailable else {
            logger.debug("Attempted prompt generation without model availability")
            throw PromptGeneratorError.modelUnavailable
        }

        guard !session.isResponding else {
            logger.debug("Attempted prompt generation while session busy")
            throw PromptGeneratorError.sessionBusy
        }

        isGenerating = true
        sessionCancelled = false

        let cardSummary = assembleCardSummary(from: cards)
        let inputTokens = estimateTokenCount(for: cardSummary)
        logger.info("Prompt generation: input ~\(inputTokens) tokens (\(cardSummary.count) chars)")

        if inputTokens > 3000 {
            logger.warning("Input approaching context window limit (4096 tokens). Consider more aggressive truncation.")
        }

        session = LanguageModelSession(instructions: ScribePromptInstructions.text)

        let options = GenerationOptions(sampling: .greedy)
        let response: LanguageModelSession.Response<PhasePromptSchema>
        do {
            response = try await session.respond(
                to: cardSummary,
                options: options,
                generable: PhasePromptSchema.self
            )

            if sessionCancelled {
                logger.debug("Cancelled session resolved")
                throw PromptGeneratorError.generationCancelled
            }
        } catch {
            logger.warning("Prompt generation error: \(error.localizedDescription)")
            isGenerating = false
            throw PromptGeneratorError.modelError(error.localizedDescription)
        }

        isGenerating = false
        sessionCancelled = false

        let formattedPrompt = formatPrompt(from: response.content)
        let outputTokens = estimateTokenCount(for: formattedPrompt)
        logger.info("Prompt generation complete: output ~\(outputTokens) tokens (\(formattedPrompt.count) chars)")

        return formattedPrompt
    }

    func cancel() {
        guard session.isResponding else { return }
        guard isGenerating else { return }

        sessionCancelled = true
        isGenerating = false
        logger.debug("Cancelling prompt generation session")
    }

    private func estimateTokenCount(for text: String) -> Int {
        // Rough heuristic: 1 token ≈ 4 characters
        // This is approximate but sufficient for context window monitoring
        return text.count / 4
    }

    private func formatPrompt(from schema: PhasePromptSchema) -> String {
        var formatted = "## Context\n\n"
        formatted += schema.context
        formatted += "\n\n## What to Build\n\n"
        formatted += schema.whatToBuild
        formatted += "\n\n## Requirements\n\n"
        formatted += schema.requirements
        formatted += "\n\n## Cards Addressed\n\n"
        for card in schema.cardsAddressed {
            formatted += "- \(card)\n"
        }
        return formatted
    }

    private func assembleCardSummary(from cards: [Card]) -> String {
        let maxTokens = 4096
        let tokensPerChar = 4
        let maxChars = maxTokens * tokensPerChar

        // Sort cards by priority: critical, high, medium, low
        let prioritySortOrder: [Priority] = [.critical, .high, .medium, .low]
        let sortedCards = cards.sorted { lhs, rhs in
            guard let lhsIndex = prioritySortOrder.firstIndex(of: lhs.priority),
                  let rhsIndex = prioritySortOrder.firstIndex(of: rhs.priority) else {
                return false
            }
            return lhsIndex < rhsIndex
        }

        var summary = "Cards to include in phase:\n\n"

        for card in sortedCards {
            let cardHeader = """
            Title: \(card.title)
            Type: \(card.type.rawValue)
            Priority: \(card.priority.rawValue)
            Status: \(card.status.rawValue)

            """

            summary += cardHeader

            let bodyPreview = card.body.prefix(500)
            summary += String(bodyPreview)
            summary += "\n\n---\n\n"
        }

        if summary.count > maxChars {
            let truncated = String(summary.prefix(maxChars - 100))
            summary = truncated + "\n\n[Content truncated to fit context window]"
        }

        return summary
    }
}
