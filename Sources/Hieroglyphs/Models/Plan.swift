import Foundation

/// Represents a plan with metadata and linked cards.
struct Plan: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let number: Int
    let slug: String
    let status: PlanStatus
    let created: Date
    let updated: Date
    let linkedCardSlugs: [String]
    let phasePrompt: String
}
