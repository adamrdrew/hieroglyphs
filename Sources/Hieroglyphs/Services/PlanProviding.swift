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

    /// Update a plan's status and cascade status changes to all linked cards.
    /// Maps plan status to corresponding card status:
    /// - planning → backlog
    /// - ready → todo
    /// - done → done
    func updatePlanStatus(plan: Plan, status: PlanStatus, projectPath: String) throws

    /// Write phase prompt content to PHASE_PROMPT.md.
    func writePhasePrompt(planSlug: String, content: String, projectPath: String) throws

    /// Remove card from all plans when a card is deleted.
    /// Scans all plan directories and removes any directory matching the card slug.
    /// Agnostic to link type (works with symlinks, hard links, or plain directories).
    /// Best-effort cleanup: logs warnings for individual failures but does not throw.
    func removeCardFromPlans(cardSlug: String, projectPath: String) throws

    /// Find the next sequential plan number for auto-increment.
    /// Scans the plans directory, finds the highest existing plan number,
    /// and returns max+1. Returns 1 if no plans exist or plans directory is missing.
    /// Malformed directory names are skipped gracefully.
    func findNextPlanNumber(projectPath: String) throws -> Int
}
