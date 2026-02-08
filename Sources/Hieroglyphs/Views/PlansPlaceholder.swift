import SwiftUI

/// Placeholder view for Plans section.
///
/// Displayed when Plans section is selected in sidebar. Plans functionality
/// is planned for a future phase.
struct PlansPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Plans",
            systemImage: "list.bullet.clipboard",
            description: Text("Plans view coming soon")
        )
    }
}
