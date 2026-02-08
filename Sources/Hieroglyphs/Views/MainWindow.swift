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
            detailColumnContent
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
            PhaseList()
        case .none:
            ContentUnavailableView(
                "Select a Project",
                systemImage: "folder",
                description: Text("Choose a project section from the sidebar to get started.")
            )
        }
    }

    @ViewBuilder
    private var detailColumnContent: some View {
        switch viewModel.selectedSection {
        case .phases:
            PhaseDetail()
        case .cards, .plans, .none:
            CardDetail()
        }
    }
}
