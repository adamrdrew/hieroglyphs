import Foundation
import FoundationModels
import SwiftUI
import os

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

        session = LanguageModelSession(instructions: ScribePromptInstructions.text)

        let response: LanguageModelSession.Response<String>
        do {
            response = try await session.respond(to: cardSummary)

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

        return response.content
    }

    func cancel() {
        guard session.isResponding else { return }
        guard isGenerating else { return }

        sessionCancelled = true
        isGenerating = false
        logger.debug("Cancelling prompt generation session")
    }

    private func assembleCardSummary(from cards: [Card]) -> String {
        let maxTokens = 4096
        let tokensPerChar = 4
        let maxChars = maxTokens * tokensPerChar

        var summary = "Cards to include in phase:\n\n"

        for card in cards {
            let cardHeader = """
            ## \(card.title)
            - Type: \(card.type.rawValue)
            - Priority: \(card.priority.rawValue)
            - Status: \(card.status.rawValue)

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
