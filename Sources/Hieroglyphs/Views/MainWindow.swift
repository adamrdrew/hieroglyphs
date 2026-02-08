import SwiftUI

struct MainWindow: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            Sidebar()
        } content: {
            middleColumnContent
        } detail: {
            CardDetail()
        }
    }

    @ViewBuilder
    private var middleColumnContent: some View {
        switch viewModel.selectedSection {
        case .cards:
            CardList()
        case .plans:
            PlansPlaceholder()
        case .phases:
            PhasesPlaceholder()
        case .none:
            ContentUnavailableView(
                "Select a Project",
                systemImage: "folder",
                description: Text("Choose a project section from the sidebar to get started.")
            )
        }
    }
}
