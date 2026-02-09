import SwiftUI

/// Displays a single project entry with title and icon.
///
/// Serves as the label for disclosure groups in the sidebar.
/// Card count summary is displayed on the Cards child item, not here.
struct SidebarProjectEntry: View {
    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding
    @State private var hasContent = false
    @State private var showingEditSheet = false

    var body: some View {
        HStack {
            Image(systemName: hasContent ? "folder.fill" : "folder")
                .foregroundStyle(.orange)

            Text(project.title)
                .font(.body)
        }
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Project", systemImage: "pencil.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
        .onAppear {
            checkContent()
        }
    }

    private func checkContent() {
        let projectPath = "\(workspacePath)/\(project.slug)"
        let cards = try? workspaceService.loadCards(
            from: projectPath,
            for: project
        )
        let hasCards = !(cards ?? []).isEmpty
        let plansPath = "\(projectPath)/plans"
        let hasPlans = FileManager.default
            .fileExists(atPath: plansPath)
            && (try? FileManager.default
                .contentsOfDirectory(atPath: plansPath))?.isEmpty == false
        hasContent = hasCards || hasPlans
    }
}
