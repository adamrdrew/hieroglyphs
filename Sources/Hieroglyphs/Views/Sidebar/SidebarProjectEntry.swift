import SwiftUI
import AppKit

/// Displays a single project entry with title and icon.
///
/// Serves as the label for disclosure groups in the sidebar.
/// Card count summary is displayed on the Cards child item, not here.
struct SidebarProjectEntry: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding
    @State private var hasContent = false
    @State private var showingEditSheet = false
    @State private var projectPendingDeletion: Project?

    var body: some View {
        HStack {
            Image(systemName: hasContent ? "folder.fill" : "folder")
                .foregroundStyle(.orange)

            Text(project.title)
                .font(.body)
        }
        .contextMenu {
            Button {
                openProjectInFinder()
            } label: {
                Label("Open in Finder", systemImage: "folder")
            }

            if project.sourceDirectory != nil {
                Button {
                    openSourceInFinder()
                } label: {
                    Label("Open Source in Finder", systemImage: "folder.badge.gearshape")
                }
            }

            Divider()

            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Project", systemImage: "pencil.circle")
            }

            Button(role: .destructive) {
                projectPendingDeletion = project
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
        .alert(
            "Delete Project",
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { if !$0 { projectPendingDeletion = nil } }
            ),
            presenting: projectPendingDeletion
        ) { project in
            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project)
                projectPendingDeletion = nil
            }
        } message: { project in
            Text("Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash.")
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

    private func openProjectInFinder() {
        let projectPath = "\(workspacePath)/\(project.slug)"

        guard FileManager.default.fileExists(atPath: projectPath) else {
            print("Error: Project directory does not exist at \(projectPath)")
            return
        }

        let url = URL(fileURLWithPath: projectPath)
        let success = NSWorkspace.shared.open(url)

        if !success {
            print("Error: Failed to open project directory at \(projectPath)")
        }
    }

    private func openSourceInFinder() {
        guard let sourceDirectory = project.sourceDirectory else {
            return
        }

        guard FileManager.default.fileExists(atPath: sourceDirectory) else {
            print("Error: Source directory does not exist at \(sourceDirectory)")
            return
        }

        let url = URL(fileURLWithPath: sourceDirectory)
        let success = NSWorkspace.shared.open(url)

        if !success {
            print("Error: Failed to open source directory at \(sourceDirectory)")
        }
    }
}
