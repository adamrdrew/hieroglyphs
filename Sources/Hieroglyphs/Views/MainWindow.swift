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
        .onChange(of: viewModel.selectedProject) { _, _ in
            viewModel.restartPhasesWatching()
        }
    }

    @ViewBuilder
    private var middleColumnContent: some View {
        Group {
            switch viewModel.selectedSection {
            case .overview(let project):
                ProjectOverview(project: project)
            case .cards:
                CardList()
            case .plans:
                PlanList()
            case .phases:
                PhaseList()
            case .pharaoh(let project):
                PharaohView(project: project)
            case .docs(let project):
                DocsList(project: project)
            case .none:
                ContentUnavailableView(
                    "Select a Project",
                    systemImage: "folder",
                    description: Text("Choose a project section from the sidebar to get started.")
                )
            }
        }
        .id(viewModel.selectedProject?.id)
    }

    @ViewBuilder
    private var detailColumnContent: some View {
        Group {
            switch viewModel.selectedSection {
            case .overview(let project):
                ProjectReadme(project: project)
            case .cards:
                CardDetail()
            case .plans:
                PlanDetail()
            case .phases:
                PhaseDetail()
            case .pharaoh(let project):
                PharaohActivityStreamView(project: project)
            case .docs:
                DocsDetail()
            case .none:
                ContentUnavailableView(
                    "Select a Project",
                    systemImage: "folder",
                    description: Text("Choose a project section from the sidebar to get started.")
                )
            }
        }
        .id(viewModel.selectedProject?.id)
    }
}
