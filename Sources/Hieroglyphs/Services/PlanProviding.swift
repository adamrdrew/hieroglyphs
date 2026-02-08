import Foundation

/// Protocol for plan I/O operations.
protocol PlanProviding {
    /// Load all plans for a given project path.
    func loadPlans(projectPath: String) throws -> [Plan]

    /// Create a new plan with the given title and number.
    func createPlan(title: String, number: Int, projectPath: String) throws -> Plan

    /// Update an existing plan's metadata.
    func updatePlan(_ plan: Plan, projectPath: String) throws

    /// Add a card to a plan by creating a symlink.
    func addCardToPlan(cardSlug: String, planSlug: String, projectPath: String) throws

    /// Remove a card from a plan by deleting the symlink.
    func removeCardFromPlan(cardSlug: String, planSlug: String, projectPath: String) throws

    /// Update a plan's status and cascade to linked cards if status is "done".
    func updatePlanStatus(plan: Plan, status: PlanStatus, projectPath: String) throws

    /// Write phase prompt content to PHASE_PROMPT.md.
    func writePhasePrompt(planSlug: String, content: String, projectPath: String) throws
}
