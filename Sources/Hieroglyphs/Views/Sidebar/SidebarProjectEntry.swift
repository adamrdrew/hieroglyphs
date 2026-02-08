import SwiftUI

/// Displays a single project entry with title and icon.
///
/// Serves as the label for disclosure groups in the sidebar.
/// Card count summary is displayed on the Cards child item, not here.
struct SidebarProjectEntry: View {
    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding

    @State private var showingEditSheet = false

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)

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
    }
}
