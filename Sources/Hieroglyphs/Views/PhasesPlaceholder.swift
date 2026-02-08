import SwiftUI

/// Placeholder view for Phases section.
///
/// Displayed when Phases section is selected in sidebar. Phases functionality
/// is planned for a future phase.
struct PhasesPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Phases",
            systemImage: "folder.badge.gearshape",
            description: Text("Phases view coming soon")
        )
    }
}
