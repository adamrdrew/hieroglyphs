import SwiftUI

/// Displays a single project entry with title and card count summary.
///
/// Shows the project title and computes card counts grouped by status,
/// displaying only non-zero counts in the format "N status • N status".
struct SidebarProjectEntry: View {
    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding

    @State private var cardCounts: [CardStatus: Int] = [:]

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.body)

                if !cardCountSummary.isEmpty {
                    Text(cardCountSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            loadCardCounts()
        }
    }

    /// Formats card counts as "N status • N status" for non-zero counts.
    private var cardCountSummary: String {
        let nonZeroCounts = cardCounts
            .filter { $0.value > 0 }
            .sorted { first, second in
                statusOrder(first.key) < statusOrder(second.key)
            }

        return nonZeroCounts
            .map { status, count in
                let label = formatStatusLabel(status)
                return "\(count) \(label)"
            }
            .joined(separator: " • ")
    }

    /// Loads cards and computes counts grouped by status.
    private func loadCardCounts() {
        do {
            let projectPath = "\(workspacePath)/\(project.slug)"
            let cards = try workspaceService.loadCards(
                from: projectPath,
                for: project
            )

            var counts: [CardStatus: Int] = [:]
            for card in cards {
                counts[card.status, default: 0] += 1
            }

            cardCounts = counts
        } catch {
            print("Failed to load cards for project \(project.slug): \(error)")
        }
    }

    /// Formats status label by replacing hyphens with spaces.
    private func formatStatusLabel(_ status: CardStatus) -> String {
        return status.rawValue.replacingOccurrences(of: "-", with: " ")
    }

    /// Returns sort order for status to ensure consistent ordering.
    private func statusOrder(_ status: CardStatus) -> Int {
        switch status {
        case .backlog: return 0
        case .todo: return 1
        case .inProgress: return 2
        case .done: return 3
        case .archived: return 4
        }
    }
}
